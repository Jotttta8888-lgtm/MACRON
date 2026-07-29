import Foundation
import AppKit

public final class AIEmailSummarizer: @unchecked Sendable {
    public static let shared = AIEmailSummarizer()
    private init() {}
    
    public struct EmailSummary: Sendable {
        public let sender: String
        public let subject: String
        public let summary: String
        public let isUrgent: Bool
        public let date: Date
    }
    
    public func summarizeUnread() async -> String {
        let script = """
        tell application "Mail"
            set unreadMessages to every message of inbox whose read status is false
            set resultList to {}
            repeat with msg in unreadMessages
                set end of resultList to (sender of msg & "|" & subject of msg & "|" & date received of msg)
            end repeat
            return resultList as string
        end tell
        """
        let output = runAppleScript(script)
        guard !output.hasPrefix("Error") else { return "No se pudo acceder a Mail.app. Verifica permisos." }
        
        let lines = output.components(separatedBy: ",").filter { !$0.isEmpty }
        var summaries: [EmailSummary] = []
        
        for line in lines.prefix(10) {
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 2 else { continue }
            let sender = parts[0].trimmingCharacters(in: .whitespaces)
            let subject = parts[1].trimmingCharacters(in: .whitespaces)
            let isUrgent = subject.lowercased().contains("urgente") || subject.lowercased().contains("importante")
            
            let prompt = "Resume este email en 1 linea: Remitente: " + sender + ", Asunto: " + subject
            let summary = await LLMConnector.shared.generate(prompt: prompt)
            
            summaries.append(EmailSummary(
                sender: sender,
                subject: subject,
                summary: summary,
                isUrgent: isUrgent,
                date: Date()
            ))
        }
        
        if summaries.isEmpty { return "No hay emails no leidos." }
        
        var result = "RESUMEN MATUTINO MACRON\n"
        result += "=======================\n"
        result += String(summaries.count) + " emails no leidos\n\n"
        
        for s in summaries {
            let icon = s.isUrgent ? "URGENTE" : "  "
            result += icon + " [" + s.sender + "] " + s.subject + "\n"
            result += "    " + s.summary + "\n\n"
        }
        
        return result
    }
    
    public func morningBriefing() async -> String {
        let summary = await summarizeUnread()
        NotificationService.shared.send(title: "Briefing Matutino", body: String(summary.prefix(100)) + "...")
        return summary
    }
    
    private func runAppleScript(_ script: String) -> String {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        try? task.run()
        task.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Error"
    }
}
