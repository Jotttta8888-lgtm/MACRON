import Foundation
import AVFoundation
import EventKit

public actor MeetingRecorderService {
    public static let shared = MeetingRecorderService()
    
    private var audioRecorder: AVAudioRecorder?
    private var isRecordingFlag = false
    public let recordingsDir: URL
    private var currentRecordingURL: URL?
    private var currentTranscription: String = ""
    private var currentSummary: String = ""
    private let eventStore = EKEventStore()
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingsDir = docs.appendingPathComponent("MACRON/Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
    }
    
    public var isRecording: Bool { isRecordingFlag }
    
    public func startRecording() -> String {
        guard !isRecordingFlag else {
            return "❌ Ya estoy grabando. Escribe 'Detener' primero."
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let basename = "reunion_\(formatter.string(from: Date()))"
        let url = recordingsDir.appendingPathComponent("\(basename).wav")
        currentRecordingURL = url
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.prepareToRecord()
            let success = audioRecorder?.record() ?? false
            
            if success {
                isRecordingFlag = true
                return "🎙️ Grabando reunion...\n📁 Se guardara en: ~/Documents/MACRON/Recordings/\nEscribe 'Detener' cuando termine."
            } else {
                return "❌ El grabador no pudo iniciar. Verifica permisos de microfono."
            }
        } catch {
            return "❌ Error al iniciar grabacion: " + error.localizedDescription
        }
    }
    
    public func stopRecording() -> String {
        guard isRecordingFlag else {
            return "❌ No estaba grabando."
        }
        
        audioRecorder?.stop()
        isRecordingFlag = false
        
        guard let url = currentRecordingURL else {
            return "❌ No se encontro el archivo de grabacion."
        }
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        let sizeMB = Double(fileSize) / 1_048_576.0
        
        // Crear evento en calendario automaticamente
        createCalendarEvent(for: url)
        
        return "✅ Grabacion guardada.\n📁 ~/Documents/MACRON/Recordings/\n📄 \(url.lastPathComponent)\n💾 \(String(format: "%.2f", sizeMB)) MB\n📅 Evento creado en Calendario con enlace al audio.\n\n📝 Escribe 'Transcribe reunion' para obtener texto."
    }
    
    private func createCalendarEvent(for audioURL: URL) {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard status == .fullAccess || status == .authorized else { return }
        
        guard let calendar = eventStore.defaultCalendarForNewEvents else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "Reunion grabada - MACRON"
        event.startDate = Date()
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        event.calendar = calendar
        event.notes = "Audio: \(audioURL.path)\n\nEscribe 'Transcribe reunion' en MACRON para obtener la transcripcion."
        event.alarms = [EKAlarm(relativeOffset: -600)]
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Error creando evento: \(error)")
        }
    }
    
    public func transcribeLastMeeting() async -> String {
        guard let url = currentRecordingURL else {
            return "❌ No hay grabacion reciente. Graba una reunion primero."
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return "❌ El archivo de audio no existe."
        }
        
        let scriptPath = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents/MACRON/meeting_transcriber.py")
        
        guard FileManager.default.fileExists(atPath: scriptPath.path) else {
            return "❌ No se encontro meeting_transcriber.py."
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/python3"
        task.arguments = [scriptPath.path, url.path]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            if task.terminationStatus != 0 {
                return "❌ Error en transcripcion:\n" + output
            }
            
            // Guardar transcripcion como .txt
            let txtURL = url.deletingPathExtension().appendingPathExtension("txt")
            try? output.write(to: txtURL, atomically: true, encoding: .utf8)
            currentTranscription = output
            
            if output.contains("WHISPER_NO_INSTALADO") {
                return "📝 Transcripcion (fallback — instala Whisper para mejores resultados):\n\n" + output.replacingOccurrences(of: "WHISPER_NO_INSTALADO\n", with: "") + "\n\n📁 Guardado en: \(txtURL.lastPathComponent)"
            }
            
            return "📝 Transcripcion guardada.\n📁 ~/Documents/MACRON/Recordings/\n📄 \(txtURL.lastPathComponent)\n\n" + output + "\n\n✅ Escribe 'Resume reunion' para un resumen con IA."
            
        } catch {
            return "❌ Error al ejecutar transcriptor: " + error.localizedDescription
        }
    }
    
    public func summarizeMeeting() async -> String {
        guard !currentTranscription.isEmpty else {
            return "❌ No hay transcripcion. Escribe 'Transcribe reunion' primero."
        }
        
        let prompt = "Resume la siguiente reunion de trabajo en 5 puntos clave, destacando decisiones y action items. Responde en espanol:\n\n" + currentTranscription
        
        let task = Process()
        task.launchPath = "/usr/bin/curl"
        task.arguments = [
            "-s", "http://localhost:11434/api/generate",
            "-d", "{\"model\":\"llama3.2\",\"prompt\":\"" + prompt.replacingOccurrences(of: "\"", with: "\\\"") + "\",\"stream\":false}"
        ]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let response = json["response"] as? String else {
                return "❌ No se pudo obtener resumen del LLM. Verifica que Ollama este corriendo."
            }
            
            currentSummary = response.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Guardar resumen como .summary.txt
            if let url = currentRecordingURL {
                let summaryURL = url.deletingPathExtension().appendingPathExtension("summary.txt")
                try? currentSummary.write(to: summaryURL, atomically: true, encoding: .utf8)
            }
            
            return "📋 Resumen guardado.\n📁 ~/Documents/MACRON/Recordings/\n\n" + currentSummary
            
        } catch {
            return "❌ Error al contactar LLM: " + error.localizedDescription
        }
    }
    
    public func playLastRecording() async -> String {
        // Buscar el archivo WAV mas reciente (porque currentRecordingURL se pierde al reiniciar)
        let files = (try? FileManager.default.contentsOfDirectory(at: recordingsDir, includingPropertiesForKeys: nil)) ?? []
        let wavs = files.filter { $0.pathExtension == "wav" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
        
        guard let url = wavs.first else {
            return "❌ No hay grabaciones. Escribe 'Graba reunion' primero."
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return "❌ El archivo de audio no existe."
        }
        
        // Usar afplay (reproductor nativo de macOS) en background
        let task = Process()
        task.launchPath = "/usr/bin/afplay"
        task.arguments = [url.path]
        
        do {
            try task.run()
            // Obtener duracion del archivo
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            return "▶️ Reproduciendo: \(url.lastPathComponent)\n⏱️ Duracion: \(String(format: "%.1f", seconds)) segundos"
        } catch {
            return "❌ Error al reproducir: " + error.localizedDescription
        }
    }
    
    public func listRecordings() -> String {
        let files = (try? FileManager.default.contentsOfDirectory(at: recordingsDir, includingPropertiesForKeys: nil)) ?? []
        
        let audios = files.filter { $0.pathExtension == "wav" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
        let txts = files.filter { $0.pathExtension == "txt" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
        
        if audios.isEmpty && txts.isEmpty {
            return "📁 La carpeta ~/Documents/MACRON/Recordings/ esta vacia."
        }
        
        var result = "📁 ~/Documents/MACRON/Recordings/\n\n"
        
        if !audios.isEmpty {
            result += "🎙️  Audios (\(audios.count)):\n"
            for (i, url) in audios.prefix(10).enumerated() {
                let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                let size = (attrs?[.size] as? Int64 ?? 0) / 1_048_576
                result += "  \(i+1). \(url.lastPathComponent) — \(size) MB\n"
            }
            result += "\n"
        }
        
        if !txts.isEmpty {
            result += "📝 Transcripciones/Resumenes (\(txts.count)):\n"
            for (i, url) in txts.prefix(10).enumerated() {
                let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                let size = (attrs?[.size] as? Int64 ?? 0) / 1024
                result += "  \(i+1). \(url.lastPathComponent) — \(size) KB\n"
            }
        }
        
        return result
    }
}
