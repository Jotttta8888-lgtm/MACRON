import Foundation
import AppKit
import Vision
import CoreGraphics

public final class ScreenCaptureAI: @unchecked Sendable {
    public static let shared = ScreenCaptureAI()
    private init() {}
    
    public func captureAndRead() async -> String {
        guard let screen = NSScreen.main else { return "❌ No se detecto pantalla." }
        let frame = screen.frame
        guard let image = CGWindowListCreateImage(frame, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else { return "❌ No se pudo capturar la pantalla." }
        return await performOCR(on: image)
    }
    
    public func captureActiveWindow() async -> String {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return "❌ No hay app activa." }
        let pid = frontApp.processIdentifier
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else { return "❌ No se pudo listar ventanas." }
        for window in windowList {
            if let windowPID = window[kCGWindowOwnerPID as String] as? Int, windowPID == pid,
               let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
               let x = bounds["X"], let y = bounds["Y"], let w = bounds["Width"], let h = bounds["Height"] {
                let frame = CGRect(x: x, y: y, width: w, height: h)
                guard let image = CGWindowListCreateImage(frame, .optionIncludingWindow, window[kCGWindowNumber as String] as! CGWindowID, .bestResolution) else { continue }
                return await performOCR(on: image)
            }
        }
        return "❌ No se pudo capturar la ventana activa."
    }
    
    private func performOCR(on image: CGImage) async -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["es-ES", "en-US"]
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            guard let observations = request.results else { return "🔍 No se detecto texto en la pantalla." }
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            return text.isEmpty ? "🔍 No se detecto texto." : "📸 **Texto detectado:**\n\n\(text)"
        } catch { return "❌ Error OCR: \(error.localizedDescription)" }
    }
    
    public func findPrice() async -> String {
        let text = await captureAndRead()
        guard !text.hasPrefix("❌"), !text.hasPrefix("🔍") else { return text }
        let pattern = #"\\$[\\d,]+(?:\\.\\d{2})?|€[\\d,]+(?:\\.\\d{2})?|[\\d,]+(?:\\.\\d{2})?\\s*(USD|EUR|\\$|€)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex?.matches(in: text, options: [], range: range) ?? []
        let prices = matches.compactMap { match -> String? in guard let r = Range(match.range, in: text) else { return nil }; return String(text[r]) }
        if prices.isEmpty { return "💰 No detecte precios en la pantalla." }
        return "💰 **Precios detectados:** \(prices.joined(separator: ", "))"
    }
    
    public func findContact() async -> String {
        let text = await captureAndRead()
        guard !text.hasPrefix("❌"), !text.hasPrefix("🔍") else { return text }
        let emailPattern = #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}"#
        let phonePattern = #"\\+?\\d{1,3}[-.\\s]?\\(?\\d{2,4}\\)?[-.\\s]?\\d{3,4}[-.\\s]?\\d{3,4}"#
        var results: [String] = []
        for pattern in [emailPattern, phonePattern] {
            let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let matches = regex?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text)) ?? []
            results.append(contentsOf: matches.compactMap { m in Range(m.range, in: text).map { String(text[$0]) } })
        }
        if results.isEmpty { return "📇 No detecte contactos en la pantalla." }
        return "📇 **Contactos detectados:**\n" + results.joined(separator: "\n")
    }
}
