import Foundation
import AppKit
import NaturalLanguage

public final class VoiceContextEngine: @unchecked Sendable {
    public static let shared = VoiceContextEngine()
    private var timer: Timer?
    private let queue = DispatchQueue(label: "macron.context", qos: .utility)
    public private(set) var currentContext: ContextSnapshot = .empty
    
    public struct ContextSnapshot: Codable, Sendable {
        public let appName: String
        public let windowTitle: String
        public let selectedText: String
        public let url: String?
        public let filePath: String?
        public let timestamp: Date
        public static let empty = ContextSnapshot(appName: "", windowTitle: "", selectedText: "", url: nil, filePath: nil, timestamp: Date.distantPast)
        public var enrichedPrompt: String {
            var parts: [String] = []
            parts.append("[CONTEXTO ACTUAL]")
            parts.append("App: \(appName)")
            if !windowTitle.isEmpty { parts.append("Ventana: \(windowTitle)") }
            if let url = url { parts.append("URL: \(url)") }
            if let path = filePath { parts.append("Archivo: \(path)") }
            if !selectedText.isEmpty { parts.append("Texto seleccionado: \"\(String(selectedText.prefix(800)))\"") }
            parts.append("[/CONTEXTO]")
            return parts.joined(separator: "\n")
        }
    }
    
    private init() {}
    public func startMonitoring(interval: TimeInterval = 2.0) {
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.queue.async { self?.captureContext() }
        }
    }
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    private func captureContext() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let appName = frontApp.localizedName ?? "Unknown"
        let pid = frontApp.processIdentifier
        var windowTitle = "", selectedText = ""
        var url: String? = nil, filePath: String? = nil
        let appRef = AXUIElementCreateApplication(pid)
        var value: AnyObject?
        if AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &value) == .success, let focused = value {
            var selValue: AnyObject?
            if AXUIElementCopyAttributeValue(focused as! AXUIElement, kAXSelectedTextAttribute as CFString, &selValue) == .success, let sel = selValue as? String { selectedText = sel }
            var fullValue: AnyObject?
            if AXUIElementCopyAttributeValue(focused as! AXUIElement, kAXValueAttribute as CFString, &fullValue) == .success, let full = fullValue as? String {
                if selectedText.isEmpty { selectedText = full }
                if full.hasPrefix("http") { url = full }
            }
        }
        var winValue: AnyObject?
        if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &winValue) == .success, let win = winValue {
            var titleValue: AnyObject?
            if AXUIElementCopyAttributeValue(win as! AXUIElement, kAXTitleAttribute as CFString, &titleValue) == .success, let title = titleValue as? String { windowTitle = title }
        }
        if url == nil, let matched = windowTitle.range(of: #"https?://[^\s]+"#, options: .regularExpression) { url = String(windowTitle[matched]) }
        if windowTitle.contains(" — ") || windowTitle.contains(" - ") {
            for sep in [" — ", " - "] {
                if let range = windowTitle.range(of: sep) {
                    let candidate = String(windowTitle[..<range.lowerBound])
                    if candidate.hasSuffix(".swift") || candidate.hasSuffix(".py") || candidate.hasSuffix(".md") || candidate.hasSuffix(".txt") { filePath = candidate; break }
                }
            }
        }
        let snapshot = ContextSnapshot(appName: appName, windowTitle: windowTitle, selectedText: selectedText, url: url, filePath: filePath, timestamp: Date())
        DispatchQueue.main.async { [weak self] in self?.currentContext = snapshot }
    }
    public func enrichPrompt(_ userPrompt: String) -> String {
        return "\(currentContext.enrichedPrompt)\n\n[PREGUNTA DEL USUARIO]\n\(userPrompt)\n[/PREGUNTA]"
    }
}
