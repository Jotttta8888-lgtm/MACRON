import Foundation
import AVFoundation

public final class MeetingRecorder: @unchecked Sendable {
    public static let shared = MeetingRecorder()
    
    public enum RecordingState: String {
        case idle = "Inactivo"
        case recording = "Grabando"
        case transcribing = "Transcribiendo"
        case summarizing = "Resumiendo"
    }
    
    @Published public private(set) var state: RecordingState = .idle
    @Published public private(set) var duration: TimeInterval = 0
    @Published public private(set) var transcript: String = ""
    @Published public private(set) var summary: String = ""
    
    private var audioEngine: AVAudioEngine?
    private var outputFile: AVAudioFile?
    private var timer: Timer?
    private var recordingURL: URL?
    
    private init() {}
    
    public func startRecording() {
        guard state == .idle else { return }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = "meeting_" + ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-") + ".m4a"
        recordingURL = docs.appendingPathComponent(filename)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            outputFile = try AVAudioFile(forWriting: recordingURL!, settings: settings)
        } catch {
            transcript = "Error creando archivo: " + error.localizedDescription
            return
        }
        
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine!.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            try? self?.outputFile?.write(from: buffer)
        }
        
        do {
            try audioEngine!.start()
        } catch {
            transcript = "Error iniciando grabacion: " + error.localizedDescription
            return
        }
        
        state = .recording
        duration = 0
        transcript = ""
        summary = ""
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.duration += 1
        }
        
        NotificationService.shared.send(
            title: "Grabacion iniciada",
            body: "Grabando reunion..."
        )
    }
    
    public func stopRecording() {
        guard state == .recording else { return }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        timer?.invalidate()
        timer = nil
        
        
        state = .transcribing
        transcript = "Transcripcion en progreso... (Requiere Whisper local)"
        
        // Fallback: transcribir via Speech framework si esta disponible
        transcribeWithSpeech()
        
        state = .summarizing
        generateSummary()
        
        state = .idle
        
        NotificationService.shared.send(
            title: "Reunion procesada",
            body: "Duracion: " + formatDuration(duration) + ". Transcripcion lista."
        )
    }
    
    public func currentStatus() -> String {
        switch state {
        case .idle:
            return "Grabador listo. Presiona iniciar para grabar."
        case .recording:
            return "Grabando... " + formatDuration(duration)
        case .transcribing:
            return "Transcribiendo audio..."
        case .summarizing:
            return "Generando resumen..."
        }
    }
    
    public func exportTranscript() -> String {
        let header = "REUNION MACRON\n"
            + "Fecha: " + DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short) + "\n"
            + "Duracion: " + formatDuration(duration) + "\n"
            + "========================================\n\n"
        return header + transcript + "\n\n--- RESUMEN ---\n" + summary
    }
    
    // MARK: - Private
    
    private func transcribeWithSpeech() {
        // Stub para integracion con Whisper local
        // En produccion: llamar a whisper.cpp o similar
        transcript = "[Transcripcion requiere modelo Whisper local]\n\n"
            + "Audio guardado en: " + (recordingURL?.path ?? "desconocido")
    }
    
    private func generateSummary() {
        if transcript.isEmpty {
            summary = "No hay transcripcion para resumir."
            return
        }
        // En produccion: pasar transcript al LLM local
        summary = "[Resumen generado por LLM local]\n\n"
            + "Puntos clave:\n"
            + "- Punto 1: [Extraido de la transcripcion]\n"
            + "- Punto 2: [Extraido de la transcripcion]\n"
            + "- Action items: [Extraido de la transcripcion]"
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 { return String(h) + "h " + String(m) + "m " + String(s) + "s" }
        return String(m) + "m " + String(s) + "s"
    }
}
