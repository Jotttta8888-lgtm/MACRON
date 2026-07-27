import Foundation

class ScreenSharingDetector: ObservableObject {
    @Published var isSharing = false
    private var timer: Timer?
    
    func start() {
        check()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.check()
        }
    }
    
    func stop() {
        timer?.invalidate()
    }
    
    private func check() {
        Task {
            do {
                let url = URL(string: "http://localhost:5001/api/screen-sharing")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let sharing = json?["is_sharing"] as? Bool ?? false
                await MainActor.run { self.isSharing = sharing }
            } catch {}
        }
    }
}
