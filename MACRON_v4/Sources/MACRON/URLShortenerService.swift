import Foundation
import AppKit

class URLShortenerService: ObservableObject {
    static let shared = URLShortenerService()
    @Published var history: [ShortenedURL] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/shorturls.json"
    
    struct ShortenedURL: Identifiable, Codable {
        var id = UUID()
        let original: String
        let short: String
        let timestamp: Date
        var clicks: Int = 0
    }
    
    func shorten(_ url: String, completion: @escaping (String?) -> Void) {
        let encoded = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
        let apiURL = "https://tinyurl.com/api-create.php?url=" + encoded
        guard let requestURL = URL(string: apiURL) else { completion(nil); return }
        let task = URLSession.shared.dataTask(with: requestURL) { data, _, _ in
            guard let data = data, let short = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                let item = ShortenedURL(original: url, short: short, timestamp: Date())
                self.history.insert(item, at: 0)
                self.save()
                completion(short)
            }
        }
        task.resume()
    }
    
    func generateQR(for item: ShortenedURL) {
        _ = QRCodeGeneratorService.shared.saveQR(
            QRCodeGeneratorService.shared.generateQR(text: item.short) ?? NSImage(),
            filename: "qr_" + String(item.id.uuidString.prefix(8))
        )
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(history)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([ShortenedURL].self, from: data) else { return }
        history = decoded
    }
}
