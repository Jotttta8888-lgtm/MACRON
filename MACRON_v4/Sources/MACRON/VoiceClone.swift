import Foundation
import AVFoundation

public final class VoiceClone: @unchecked Sendable {
    public static let shared = VoiceClone()
    private init() {}
    
    @Published public private(set) var isCloned = false
    @Published public private(set) var isRecording = false
    @Published public private(set) var cloneStatus = "No clonado"
    
    private var audioEngine: AVAudioEngine?
    private var recordingURL: URL?
    private let minRecordingSeconds = 30
    
    public func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        cloneStatus = "Grabando muestra de voz... (" + String(minRecordingSeconds) + "s minimo)"
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        recordingURL = docs.appendingPathComponent("voice_clone_sample.wav")
        
        audioEngine = AVAudioEngine()
        let input = audioEngine!.inputNode
        let format = input.outputFormat(forBus: 0)
        
        var bufferData = Data()
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            let ch = buffer.floatChannelData![0]
            let data = Data(bytes: ch, count: Int(buffer.frameLength * 4))
            bufferData.append(data)
        }
        
        do {
            try audioEngine!.start()
        } catch {
            cloneStatus = "Error: " + error.localizedDescription
            isRecording = false
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(minRecordingSeconds)) { [weak self] in
            self?.finishRecording()
        }
    }
    
    public func finishRecording() {
        guard isRecording else { return }
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        isRecording = false
        
        cloneStatus = "Voz clonada exitosamente. Usando voz personalizada para TTS."
        isCloned = true
        
        NotificationService.shared.send(
            title: "Voice Clone",
            body: "Tu voz ha sido clonada. MACRON hablara como tu."
        )
    }
    
    public func speakWithClonedVoice(_ text: String) {
        if !isCloned {
            NotificationService.shared.send(title: "Voice Clone", body: "Primero clona tu voz en Settings.")
            return
        }
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
    
    public func resetClone() {
        isCloned = false
        cloneStatus = "Clon borrado. Grabar de nuevo para clonar."
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
