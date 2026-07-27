import Foundation

class BreathingGuideService: ObservableObject {
    static let shared = BreathingGuideService()
    @Published var isActive = false
    @Published var currentPhase = "Listo"
    @Published var progress = 0.0
    private var timer: Timer?
    
    let patterns: [String: (inhale: Int, hold: Int, exhale: Int, hold2: Int)] = [
        "4-7-8": (4, 7, 8, 0),
        "Box": (4, 4, 4, 4),
        "Relax": (4, 0, 6, 0),
        "Energize": (2, 0, 2, 0)
    ]
    
    func start(pattern: String = "4-7-8") {
        guard let p = patterns[pattern] else { return }
        isActive = true
        currentPhase = "Inhala"
        progress = 0.0
        runPhase(pattern: pattern, phase: 0, config: p)
        NotificationService.shared.send(title: "MACRON Breathe", body: "Ejercicio iniciado: " + pattern)
    }
    
    func stop() {
        isActive = false
        timer?.invalidate()
        currentPhase = "Listo"
        progress = 0.0
    }
    
    private func runPhase(pattern: String, phase: Int, config: (inhale: Int, hold: Int, exhale: Int, hold2: Int)) {
        guard isActive else { return }
        let durations = [config.inhale, config.hold, config.exhale, config.hold2]
        let names = ["Inhala", "Mantén", "Exhala", "Mantén"]
        let duration = Double(durations[phase])
        guard duration > 0 else {
            runPhase(pattern: pattern, phase: (phase + 1) % 4, config: config)
            return
        }
        currentPhase = names[phase]
        progress = 0.0
        var elapsed = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsed += 0.1
            self.progress = elapsed / duration
            if elapsed >= duration {
                self.timer?.invalidate()
                self.runPhase(pattern: pattern, phase: (phase + 1) % 4, config: config)
            }
        }
    }
}
