import Foundation

class PomodoroProService: ObservableObject {
    static let shared = PomodoroProService()
    @Published var timeRemaining = 25 * 60
    @Published var isRunning = false
    @Published var sessionCount = 0
    @Published var currentPhase = "Focus"
    
    private var timer: Timer?
    private let focusTime = 25 * 60
    private let breakTime = 5 * 60
    private let longBreakTime = 15 * 60
    
    func start() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in self.tick() }
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
    }
    
    func reset() {
        pause()
        timeRemaining = focusTime
        currentPhase = "Focus"
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            completePhase()
        }
    }
    
    private func completePhase() {
        if currentPhase == "Focus" {
            sessionCount += 1
            timeRemaining = (sessionCount % 4 == 0) ? longBreakTime : breakTime
            currentPhase = (sessionCount % 4 == 0) ? "Long Break" : "Break"
        } else {
            timeRemaining = focusTime
            currentPhase = "Focus"
        }
        NotificationService.shared.send(title: "MACRON Pomodoro", body: "Fase completada: " + currentPhase)
    }
}
