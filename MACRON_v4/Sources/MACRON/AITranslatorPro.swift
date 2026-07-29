import Foundation
import AppKit
import NaturalLanguage

public final class AITranslatorPro: @unchecked Sendable {
    public static let shared = AITranslatorPro()
    private init() {}
    
    public let supportedLanguages = [
        "es": "Espanol", "en": "English", "fr": "Francais", "de": "Deutsch",
        "it": "Italiano", "pt": "Portugues", "ja": "Japanese", "zh": "Chinese",
        "ko": "Korean", "ru": "Russian", "ar": "Arabic", "hi": "Hindi"
    ]
    
    public func detectLanguage(_ text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.language])
        tagger.string = text
        let lang = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .language).0?.rawValue ?? "es"
        return supportedLanguages[lang] ?? lang
    }
    
    public func translate(_ text: String, to targetLang: String) async -> String {
        let detected = detectLanguage(text)
        let prompt = "Traduce el siguiente texto de " + detected + " a " + targetLang + ". Responde SOLO con la traduccion, sin explicaciones:\n\n" + text
        return await LLMConnector.shared.generate(prompt: prompt)
    }
    
    public func translateSelection() async -> String {
        let pb = NSPasteboard.general
        guard let text = pb.string(forType: .string), !text.isEmpty else {
            return "No hay texto seleccionado en el portapapeles."
        }
        let result = await translate(text, to: "Espanol")
        pb.clearContents()
        pb.setString(result, forType: .string)
        return "Traduccion copiada al portapapeles:\n" + result
    }
    
    public func quickTranslate(_ text: String) async -> String {
        return await translate(text, to: "Espanol")
    }
}
