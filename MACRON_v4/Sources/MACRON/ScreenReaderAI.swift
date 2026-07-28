import Foundation
import AppKit
import AVFoundation

public final class ScreenReaderAI: NSObject, @unchecked Sendable {
    public static let shared = ScreenReaderAI()
    private let synthesizer = AVSpeechSynthesizer()
    private let queue = DispatchQueue(label: "macron.screenreader")
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    public func readSelectedText() -> String {
        let ctx = VoiceContextEngine.shared.currentContext
        let text = ctx.selectedText
        guard !text.isEmpty else { return "❌ No hay texto seleccionado. Selecciona algo primero." }
        speak(text)
        return "🗣️ Leyendo \(text.count) caracteres..."
    }
    
    public func speak(_ text: String, rate: Float = 0.5) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.es-ES.Monica") ?? AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
    
    public func speakPro(_ text: String) {
        stop()
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        for (index, sentence) in sentences.enumerated() {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let utterance = AVSpeechUtterance(string: trimmed + ".")
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.enhanced.es-ES.Monica") ?? AVSpeechSynthesisVoice(language: "es-ES")
            utterance.rate = 0.45
            utterance.pitchMultiplier = 1.05
            utterance.preUtteranceDelay = index == 0 ? 0 : 0.3
            utterance.postUtteranceDelay = 0.2
            synthesizer.speak(utterance)
        }
    }
    
    public func stop() { if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) } }
    public var isSpeaking: Bool { synthesizer.isSpeaking }
}

extension ScreenReaderAI: AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {}
}
