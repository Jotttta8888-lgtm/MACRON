import Foundation
import AppKit
import Vision
import CoreGraphics
import ScreenCaptureKit

public final class ScreenCaptureAI: @unchecked Sendable {
    public static let shared = ScreenCaptureAI()
    private init() {}
    
    public func captureAndRead() async -> String {
        let displayID = CGMainDisplayID()
        guard let image = CGDisplayCreateImage(displayID) else { return "❌ No se pudo capturar la pantalla." }
        return await performOCR(on: image)
    }
    
    public func captureActiveWindow() async -> String {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return "❌ No hay app activa." }
        let pid = frontApp.processIdentifier
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let window = content.windows.first(where: { $0.owningApplication?.processID == pid }) else {
                return "❌ Ventana no encontrada. Capturando pantalla completa..."
            }
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let config = SCStreamConfiguration()
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            return await performOCR(on: image)
        } catch {
            return "❌ Error ScreenCaptureKit: \(error.localizedDescription)"
        }
    }
    
    private func performOCR(on image: CGImage) async -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["es-ES", "en-US"]
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
            guard let observations = request.results else { return "🔍 No se detecto texto." }
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
        if prices.isEmpty { return "💰 No detecte precios." }
        return "💰 **Precios:** \(prices.joined(separator: ", "))"
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
        if results.isEmpty { return "📇 No detecte contactos." }
        return "📇 **Contactos:**\n" + results.joined(separator: "\n")
    }
}
