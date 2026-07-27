import Foundation
import AppKit

class MeetingAssistantService: ObservableObject {
    static let shared = MeetingAssistantService()
    @Published var isInMeeting: Bool = false
    @Published var meetingApp: String = ""
    
    private let meetingApps = ["zoom.us", "Microsoft Teams", "FaceTime", "Webex", "Google Chrome", "Safari"]
    private var timer: Timer?
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.detectMeeting()
        }
        detectMeeting()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
    }
    
    private func detectMeeting() {
        let workspace = NSWorkspace.shared
        guard let frontApp = workspace.frontmostApplication else { return }
        let appName = frontApp.localizedName ?? ""
        let bundleId = frontApp.bundleIdentifier ?? ""
        
        let isMeeting = meetingApps.contains { appName.contains($0) || bundleId.contains($0.lowercased()) }
        
        DispatchQueue.main.async {
            if isMeeting && !self.isInMeeting {
                self.isInMeeting = true
                self.meetingApp = appName
                NotificationService.shared.send(title: "MACRON", body: "Reunion detectada en " + appName + ". Silenciando notificaciones.")
            } else if !isMeeting && self.isInMeeting {
                self.isInMeeting = false
                self.meetingApp = ""
                NotificationService.shared.send(title: "MACRON", body: "Reunion finalizada.")
            }
        }
    }
}
