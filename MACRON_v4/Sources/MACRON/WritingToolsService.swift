import AppKit

class WritingToolsService: NSObject {
    static let shared = WritingToolsService()
    
    func setup() {
        NSApp.servicesProvider = self
    }
    
    @objc func rewriteText(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        processText(pboard, action: "rewrite", error: error)
    }
    
    @objc func summarizeText(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        processText(pboard, action: "summarize", error: error)
    }
    
    @objc func proofreadText(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        processText(pboard, action: "proofread", error: error)
    }
    
    private func processText(_ pboard: NSPasteboard, action: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let text = pboard.string(forType: .string), !text.isEmpty else {
            error.pointee = "No hay texto seleccionado" as NSString
            return
        }
        DispatchQueue.main.async {
            NotificationService.shared.send(title: "MACRON", body: "\(action.capitalized) en proceso...")
        }
        Task {
            do {
                let url = URL(string: "http://localhost:5001/api/writing-tools")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: ["text": text, "action": action])
                let (data, response) = try await URLSession.shared.data(for: request)
                if let r = response as? HTTPURLResponse, r.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let result = json["result"] {
                    DispatchQueue.main.async {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(result, forType: .string)
                        NotificationService.shared.send(title: "MACRON", body: "\(action.capitalized) listo. Pegalo donde quieras.")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    NotificationService.shared.send(title: "MACRON", body: "Error en \(action)")
                }
            }
        }
    }
}
