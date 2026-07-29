import Foundation
import AppKit

public final class CodeDebugger: @unchecked Sendable {
    public static let shared = CodeDebugger()
    private init() {}
    
    public struct ErrorReport: Sendable {
        public let file: String
        public let line: Int
        public let message: String
        public let suggestion: String
        public let severity: Severity
        
        public enum Severity: String, Sendable {
            case error = "Error"
            case warning = "Warning"
            case info = "Info"
        }
    }
    
    public func analyzeXcodeSelection() async -> String {
        let script = """
        tell application "Xcode"
            set selectedText to ""
            tell front document
                set selectedText to contents of selection
            end tell
            return selectedText
        end tell
        """
        let code = runAppleScript(script)
        guard !code.isEmpty, !code.hasPrefix("Error") else {
            return "No se detecto codigo seleccionado en Xcode."
        }
        return await analyzeCode(code, source: "Xcode")
    }
    
    public func analyzeTerminalOutput() async -> String {
        let script = """
        tell application "Terminal"
            set terminalText to contents of front window
            set lastLines to last paragraph of terminalText
            return lastLines
        end tell
        """
        let output = runAppleScript(script)
        guard !output.isEmpty else { return "No se pudo leer Terminal." }
        return await analyzeCode(output, source: "Terminal")
    }
    
    public func analyzeCode(_ code: String, source: String) async -> String {
        let prompt = "Eres un experto en debugging. Analiza este codigo/error y sugiere una solucion paso a paso:\n\nFuente: " + source + "\n```\n" + code + "\n```\n\nResponde en espanol con: 1) Diagnostico, 2) Causa raiz, 3) Solucion, 4) Codigo corregido."
        let response = await LLMConnector.shared.generate(prompt: prompt)
        return "DEBUG MACRON\n===========\nFuente: " + source + "\n\n" + response
    }
    
    public func explainError(_ errorText: String) async -> String {
        let prompt = "Explica este error de forma simple para un desarrollador:\n" + errorText
        return await LLMConnector.shared.generate(prompt: prompt)
    }
    
    private func runAppleScript(_ script: String) -> String {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
