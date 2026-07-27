import Foundation

class FocusDetector: ObservableObject {
    @Published var isInMeeting = false
    @Published var meetingTitle = ""
    private var timer: Timer?
    private let baseURL = "http://localhost:5001"

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        checkMeeting()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.checkMeeting()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkMeeting() {
        Task {
            do {
                let url = URL(string: baseURL + "/api/calendar/has-meeting-now")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let hasMeeting = json?["has_meeting"] as? Bool ?? false
                let title = json?["event"] as? String ?? "Reunión"
                await MainActor.run {
                    self.isInMeeting = hasMeeting
                    self.meetingTitle = title
                }
            } catch { print("[FocusDetector] Error: \\(error)") }
        }
    }
}
