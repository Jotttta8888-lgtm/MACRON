import Foundation
import Vision
import CoreGraphics
import AppKit

public actor ScreenOCRService {
    public static let shared = ScreenOCRService()
    private init() {}
    
    public func captureAndRecognize() async -> String {
        // 1. Capturar pantalla principal
        guard let displayID = CGMainDisplayID() as UInt32? else {
            return "❌ No se pudo acceder a la pantalla."
        }
        
        guard let cgImage = CGDisplayCreateImage(displayID) else {
            return "❌ No se pudo capturar la pantalla."
        }
        
        // 2. Preparar request de OCR con Vision
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["es-ES", "en-US"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            guard let observations = request.results else {
                return "❌ No se detectó texto en la pantalla."
            }
            
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            
            if text.isEmpty {
                return "📄 Pantalla analizada. No se encontró texto legible."
            }
            
            // Guardar en clipboard para conveniencia
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            
            return "📄 Texto extraído de la pantalla:\n\n" + text + "\n\n✅ Copiado al portapapeles."
            
        } catch {
            return "❌ Error en OCR: " + error.localizedDescription
        }
    }
    
    public func captureToFile() async -> String {
        guard let displayID = CGMainDisplayID() as UInt32? else {
            return "❌ No se pudo acceder a la pantalla."
        }
        guard let cgImage = CGDisplayCreateImage(displayID) else {
            return "❌ No se pudo capturar la pantalla."
        }
        
        let nsImage = NSImage(cgImage: cgImage, size: .zero)
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return "❌ No se pudo convertir la captura."
        }
        
        let path = NSHomeDirectory() + "/Desktop/ScreenOCR_" + String(Int(Date().timeIntervalSince1970)) + ".png"
        let url = URL(fileURLWithPath: path)
        try? pngData.write(to: url)
        
        return "📸 Captura guardada: " + path
    }
}
