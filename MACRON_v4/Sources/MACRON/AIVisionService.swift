import Vision
import AppKit

class AIVisionService {
    static let shared = AIVisionService()
    
    func recognizeText(in image: NSImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion("Error: No se pudo convertir la imagen")
            return
        }
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil, let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("Error en OCR: " + (error?.localizedDescription ?? "Desconocido"))
                return
            }
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            completion(text.isEmpty ? "No se detecto texto" : text)
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["es-CO", "en-US"]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do { try handler.perform([request]) }
            catch { completion("Error: " + error.localizedDescription) }
        }
    }
    
    func recognizeTextFromScreen(completion: @escaping (String) -> Void) {
        guard let screen = NSScreen.main else { completion("No se encontro pantalla"); return }
        let rect = screen.frame
        guard let cgImage = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
            completion("No se pudo capturar pantalla")
            return
        }
        let image = NSImage(cgImage: cgImage, size: rect.size)
        recognizeText(in: image, completion: completion)
    }
}
