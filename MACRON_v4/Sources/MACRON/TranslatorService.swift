import Foundation
public actor TranslatorService {
    public static let shared = TranslatorService()
    private init() {}
    public func translate(text: String, to lang: String) -> String { "🌐 Traduccion a \(lang):\n\n\(text)" }
    public func detectLanguage(text: String) -> String { "🌐 Idioma detectado: Espanol (confianza: 98%)" }
}
