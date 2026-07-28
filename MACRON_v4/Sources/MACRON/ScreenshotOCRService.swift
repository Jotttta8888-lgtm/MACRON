import Foundation
import Vision
import AppKit

class ScreenshotOCRService: ObservableObject {
    static let shared = ScreenshotOCRService()
    @Published var lastExtractedText = ""
    
    func captureAndRecognize() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        let path = NSHomeDirectory() + "/Documents/MACRON/ocr_temp.png"
        task.arguments = ["-i", path]
        task.terminationHandler = { _ in
            self.recognizeText(from: path)
        }
        try? task.run()
    }
    
    func recognizeText(from path: String) {
        guard let image = NSImage(contentsOfFile: path),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\\n")
            DispatchQueue.main.async {
                self.lastExtractedText = text
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                NotificationService.shared.send(title: "MACRON OCR", body: "Texto copiado al portapapeles")
            }
        }
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}
