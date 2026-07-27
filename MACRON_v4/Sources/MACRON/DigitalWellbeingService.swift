import Foundation
import AppKit

class DigitalWellbeingService: ObservableObject {
    static let shared = DigitalWellbeingService()
    @Published var focusModeActive = false
    @Published var dailyScreenTime: [String: TimeInterval] = [:]
    
    private var focusTimer: Timer?
    private let limits: [String: TimeInterval] = [
        "Twitter": 1800,
        "Instagram": 1800,
        "YouTube": 3600,
        "TikTok": 1800
    ]
    
    func startTracking() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.checkLimits()
        }
    }
    
    func toggleFocusMode() {
        focusModeActive.toggle()
        if focusModeActive {
            NotificationService.shared.send(title: "MACRON Focus", body: "Modo concentracion activado. Notificaciones silenciadas.")
        } else {
            NotificationService.shared.send(title: "MACRON Focus", body: "Modo concentracion desactivado.")
        }
    }
    
    private func checkLimits() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication?.localizedName else { return }
        dailyScreenTime[frontApp, default: 0] += 60
        if let limit = limits[frontApp], dailyScreenTime[frontApp, default: 0] >= limit {
            NotificationService.shared.send(title: "MACRON Wellbeing", body: "Limite alcanzado en " + frontApp + ". Toma un descanso.")
        }
    }
}
