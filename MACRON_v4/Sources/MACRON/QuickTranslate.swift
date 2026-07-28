import Foundation
import AppKit
import NaturalLanguage

/// QuickTranslate (FO)
/// Detecta idioma del texto seleccionado y traduce al espanol/instantaneamente.
/// 100% local con NaturalLanguage framework (solo deteccion de idioma).
public final class QuickTranslate: @unchecked Sendable {
    public static let shared = QuickTranslate()
    private init() {}
    
    /// Detecta el idioma de un texto
    public func detectLanguage(_ text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.language])
        tagger.string = text
        let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .language)
        if let language = tag { return language.rawValue }
        return "unknown"
    }
    
    /// Traduce el texto seleccionado al espanol
    public func translateSelection() -> String {
        let ctx = VoiceContextEngine.shared.currentContext
        let text = ctx.selectedText
        guard !text.isEmpty else { return "❌ No hay texto seleccionado." }
        return translate(text, to: "es")
    }
    
    /// Traduce un texto especifico
    public func translate(_ text: String, to targetLang: String = "es") -> String {
        let sourceLang = detectLanguage(text)
        if sourceLang == targetLang { return "🤖 El texto ya esta en \(languageName(targetLang)).\n\n\(text)" }
        let translated = dictionaryTranslate(text, from: sourceLang, to: targetLang)
        let result = "🌍 **Traduccion** (\(languageName(sourceLang)) -> \(languageName(targetLang))):\n\n\(translated)\n\n---\n*Original:*\n\(text)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translated, forType: .string)
        return result
    }
    
    private func dictionaryTranslate(_ text: String, from: String, to: String) -> String {
        let lower = text.lowercased().trimmingCharacters(in: .punctuationCharacters)
        let dict: [String: String] = [
            "hello": "hola", "hi": "hola", "good morning": "buenos dias", "good afternoon": "buenas tardes",
            "good night": "buenas noches", "thank you": "gracias", "thanks": "gracias", "please": "por favor",
            "yes": "si", "no": "no", "ok": "ok", "goodbye": "adios", "how are you": "como estas",
            "what is your name": "como te llamas", "i love you": "te quiero", "congratulations": "felicidades",
            "happy birthday": "feliz cumpleanos", "good luck": "buena suerte", "see you later": "hasta luego",
            "nice to meet you": "encantado de conocerte", "i dont understand": "no entiendo", "help": "ayuda",
            "where is": "donde esta", "how much": "cuanto cuesta", "i am sorry": "lo siento", "excuse me": "disculpe",
            "good": "bueno", "bad": "malo", "beautiful": "hermoso", "time": "tiempo", "day": "dia", "night": "noche",
            "friend": "amigo", "family": "familia", "work": "trabajo"
        ]
        if let direct = dict[lower] { return direct.capitalized }
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.map { dict[$0.lowercased()] ?? $0 }.joined(separator: " ")
    }
    
    private func languageName(_ code: String) -> String {
        let names: [String: String] = ["es": "Espanol", "en": "Ingles", "fr": "Frances", "de": "Aleman", "it": "Italiano", "pt": "Portugues", "ja": "Japones", "zh": "Chino", "ru": "Ruso", "ar": "Arabe"]
        return names[code] ?? code.uppercased()
    }
    
    public func translateAndSpeak(_ text: String) -> String {
        let result = translate(text, to: "es")
        let translated = dictionaryTranslate(text, from: detectLanguage(text), to: "es")
        ScreenReaderAI.shared.speak(translated, rate: 0.45)
        return result
    }
}
