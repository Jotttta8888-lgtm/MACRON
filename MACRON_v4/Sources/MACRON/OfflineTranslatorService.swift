import Foundation
import NaturalLanguage

class OfflineTranslatorService {
    static let shared = OfflineTranslatorService()
    
    func translate(_ text: String, to target: String = "en") -> String {
        let tagger = NLTagger(tagSchemes: [.language])
        tagger.string = text
        let lang = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .language).0?.rawValue ?? "es"
        
        let script = """
        tell application "Shortcuts Events"
            run shortcut "Traducir Texto" with input "\(text)"
        end tell
        """
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return text }
        let result = appleScript.executeAndReturnError(&errorInfo)
        return result.stringValue ?? text
    }
    
    func detectLanguage(_ text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.language])
        tagger.string = text
        return tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .language).0?.rawValue ?? "desconocido"
    }
}
