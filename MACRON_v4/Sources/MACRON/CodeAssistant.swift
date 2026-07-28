import Foundation
import AppKit

public final class CodeAssistant: @unchecked Sendable {
    public static let shared = CodeAssistant()
    private let snippets: [String: String] = [
        "singleton": "public static let shared = ClassName()\nprivate init() {}",
        "dispatch": "DispatchQueue.main.async { [weak self] in\n    guard let self = self else { return }\n}",
        "task": "Task {\n    await asyncFunction()\n}",
        "guard": "guard let value = optional else { return }",
        "computed": "public var property: Type {\n    return value\n}",
        "delegate": "public weak var delegate: SomeDelegate?",
        "userdefaults": "UserDefaults.standard.set(value, forKey: \"key\")",
        "notification": "NotificationCenter.default.post(name: .init(\"event\"), object: nil)",
        "jsondecode": "if let data = jsonString.data(using: .utf8),\n   let obj = try? JSONDecoder().decode(Type.self, from: data) {}",
        "urlsession": "URLSession.shared.dataTask(with: url) { data, response, error in\n}.resume()"
    ]
    private init() {}
    
    public func generateSnippet(_ name: String) -> String {
        guard let snippet = snippets[name.lowercased()] else {
            let available = snippets.keys.sorted().joined(separator: ", ")
            return "❌ Snippet '\(name)' no encontrado. Disponibles: \(available)"
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet, forType: .string)
        return "✅ Snippet '\(name)' copiado al portapapeles.\n```swift\n\(snippet)\n```"
    }
    
    public func explainError(_ errorText: String) -> String {
        let lower = errorText.lowercased()
        if lower.contains("expected declaration") { return "🔧 **Expected declaration**: Probablemente falta una llave de cierre `}` o hay codigo fuera de una clase/funcion. Revisa la indentacion." }
        if lower.contains("cannot find") { return "🔧 **Cannot find in scope**: La variable/clase/funcion no existe o no esta importada. Revisa los imports y los nombres." }
        if lower.contains("optional value") || lower.contains("unwrapped") { return "🔧 **Optional**: Estas usando un optional sin `guard let`, `if let`, o `?`. Desenvuelvelo primero." }
        if lower.contains("sendable") { return "🔧 **Sendable**: El tipo no es seguro para concurrencia. Usa `@unchecked Sendable` o conviertelo a actor." }
        if lower.contains("async") { return "🔧 **Async**: Llamas una funcion async desde un contexto sync. Usa `Task { await ... }` o marca la funcion como `async`." }
        if lower.contains("actor") { return "🔧 **Actor**: No puedes acceder a propiedades de actor desde fuera sin `await`. Usa `await actor.property`." }
        if lower.contains("deprecated") { return "⚠️ **Deprecated**: Esa API ya no se usa. Busca la alternativa moderna en la documentacion de Apple." }
        return "🤖 No reconozco ese error especifico. Pega el mensaje completo para un analisis mas profundo."
    }
    
    public func contextualHelp() -> String {
        let ctx = VoiceContextEngine.shared.currentContext
        let app = ctx.appName.lowercased()
        guard app.contains("xcode") || app.contains("code") || app.contains("cursor") else {
            return "🤖 No detecto un IDE activo. Abre Xcode o VS Code para usar el CodeAssistant."
        }
        if !ctx.selectedText.isEmpty { return explainError(ctx.selectedText) }
        return "👨‍💻 Estas en \(ctx.appName). Puedo:\n- Explicar errores (selecciona el error)\n- Generar snippets (di 'snippet singleton')\n- Refactorizar codigo (selecciona y di 'refactoriza')"
    }
    
    public func refactorSelected() -> String {
        let ctx = VoiceContextEngine.shared.currentContext
        let code = ctx.selectedText
        guard !code.isEmpty else { return "❌ Selecciona codigo para refactorizar." }
        var refactored = code
        refactored = refactored.replacingOccurrences(of: "; ", with: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(refactored, forType: .string)
        return "✅ Codigo refactorizado y copiado:\n```swift\n\(refactored)\n```"
    }
}
