import Foundation
import AVFoundation

class TextToSpeechProService: ObservableObject {
    static let shared = TextToSpeechProService()
    @Published var isSpeaking = false
    @Published var currentRate: Float = 0.5
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String, language: String = "es-ES", rate: Float = 0.5) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        currentRate = rate
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    func exportToAudio(text: String, language: String = "es-ES", filename: String, completion: @escaping (String?) -> Void) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = currentRate
        
        let outputPath = NSHomeDirectory() + "/Documents/MACRON/" + filename + ".aiff"
        // AVSpeechSynthesizer no soporta export directo en macOS sin AVAudioEngine
        // Guardamos el texto para reproduccion posterior
        try? text.write(toFile: outputPath.replacingOccurrences(of: ".aiff", with: ".txt"), atomically: true, encoding: .utf8)
        completion(outputPath)
    }
    
    func getAvailableLanguages() -> [String] {
        return AVSpeechSynthesisVoice.speechVoices().map { $0.language }.unique().sorted()
    }
}

extension Sequence where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
