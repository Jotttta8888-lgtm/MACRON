import Foundation

class NightModeSchedulerService: ObservableObject {
    static let shared = NightModeSchedulerService()
    @Published var isScheduled = false
    @Published var scheduleStart = Date()
    @Published var scheduleEnd = Date()
    private var timer: Timer?
    
    func enableSchedule(startHour: Int, endHour: Int) {
        isScheduled = true
        let cal = Calendar.current
        var startComp = cal.dateComponents([.year, .month, .day], from: Date())
        startComp.hour = startHour
        startComp.minute = 0
        var endComp = startComp
        endComp.hour = endHour
        scheduleStart = cal.date(from: startComp) ?? Date()
        scheduleEnd = cal.date(from: endComp) ?? Date()
        startTimer()
        NotificationService.shared.send(title: "MACRON Night Mode", body: "Programado: \(startHour):00 - \(endHour):00")
    }
    
    func disableSchedule() {
        isScheduled = false
        timer?.invalidate()
        NotificationService.shared.send(title: "MACRON Night Mode", body: "Programacion desactivada")
    }
    
    func toggleDarkMode(_ enabled: Bool) {
        _ = enabled ? "Dark" : "Light"
        let script = "tell application \\\"System Events\\\" to tell appearance preferences to set dark mode to " + (enabled ? "true" : "false")
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        try? task.run()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.checkSchedule()
        }
        checkSchedule()
    }
    
    private func checkSchedule() {
        guard isScheduled else { return }
        let now = Date()
        let cal = Calendar.current
        let hour = cal.component(.hour, from: now)
        let startHour = cal.component(.hour, from: scheduleStart)
        let endHour = cal.component(.hour, from: scheduleEnd)
        let shouldBeDark = startHour < endHour ? (hour >= startHour && hour < endHour) : (hour >= startHour || hour < endHour)
        toggleDarkMode(shouldBeDark)
    }
}
