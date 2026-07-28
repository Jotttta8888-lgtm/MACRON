import Foundation

class NetworkSpeedTestService: ObservableObject {
    static let shared = NetworkSpeedTestService()
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var latency: Double = 0
    @Published var isTesting = false
    
    func testLatency(completion: @escaping (Double) -> Void) {
        let start = Date()
        guard let url = URL(string: "https://www.google.com") else { completion(0); return }
        let task = URLSession.shared.dataTask(with: url) { _, _, _ in
            let ms = Date().timeIntervalSince(start) * 1000
            DispatchQueue.main.async {
                self.latency = ms
                completion(ms)
            }
        }
        task.resume()
    }
    
    func testDownload(completion: @escaping (Double) -> Void) {
        isTesting = true
        downloadSpeed = 0
        let start = Date()
        let testURL = "https://speed.hetzner.de/10MB.bin"
        guard let url = URL(string: testURL) else { isTesting = false; completion(0); return }
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            let elapsed = Date().timeIntervalSince(start)
            let bytes = Double(data?.count ?? 0)
            let mbps = (bytes * 8 / 1_000_000) / elapsed
            DispatchQueue.main.async {
                self.downloadSpeed = mbps
                self.isTesting = false
                completion(mbps)
            }
        }
        task.resume()
    }
    
    func runFullTest() {
        testLatency { _ in
            self.testDownload { _ in
                NotificationService.shared.send(
                    title: "MACRON Speed Test",
                    body: String(format: "Download: %.1f Mbps | Latency: %.0f ms", self.downloadSpeed, self.latency)
                )
            }
        }
    }
}
