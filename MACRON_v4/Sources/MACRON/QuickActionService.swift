import Cocoa

class QuickActionService: NSObject {
    static let shared = QuickActionService()
    
    func setup() {
        NSApp.servicesProvider = self
    }
    
    @objc func processText(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let text = pboard.string(forType: .string), !text.isEmpty else {
            error.pointee = "No hay texto seleccionado" as NSString
            return
        }
        DispatchQueue.main.async {
            // No forzar foco - Quick Action silencioso
            NotificationCenter.default.post(name: .quickActionReceived, object: nil, userInfo: ["text": text])
            Task {
                do {
                    let url = URL(string: "http://localhost:5001/api/voice-action")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: ["text": text])
                    let (_, response) = try await URLSession.shared.data(for: request)
                    if let r = response as? HTTPURLResponse, r.statusCode == 200 {
                        NotificationService.shared.send(title: "MACRON", body: "Procesado: \(text.prefix(60))...")
                    }
                } catch {
                    NotificationService.shared.send(title: "MACRON", body: "Error al procesar texto")
                }
            }
        }
    }
}
