import Foundation

class CountdownTimerService: ObservableObject {
    static let shared = CountdownTimerService()
    @Published var events: [CountdownEvent] = []
    @Published var menuBarText = ""
    private var timer: Timer?
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/countdowns.json"
    
    struct CountdownEvent: Identifiable, Codable {
        var id = UUID()
        let name: String
        let targetDate: Date
        let color: String
    }
    
    func addEvent(name: String, date: Date, color: String = "blue") {
        let event = CountdownEvent(name: name, targetDate: date, color: color)
        events.append(event)
        save()
        startTimer()
        NotificationService.shared.send(title: "MACRON Countdown", body: "Evento añadido: " + name)
    }
    
    func timeRemaining(for event: CountdownEvent) -> String {
        let diff = event.targetDate.timeIntervalSince(Date())
        if diff <= 0 { return "¡Llego el momento!" }
        let days = Int(diff) / 86400
        let hours = (Int(diff) % 86400) / 3600
        let mins = (Int(diff) % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h \(mins)m" }
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.updateMenuBar()
        }
        updateMenuBar()
    }
    
    func updateMenuBar() {
        guard let next = events.sorted(by: { $0.targetDate < $1.targetDate }).first(where: { $0.targetDate > Date() }) else {
            menuBarText = ""
            return
        }
        menuBarText = next.name + ": " + timeRemaining(for: next)
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(events)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([CountdownEvent].self, from: data) else { return }
        events = decoded
        startTimer()
    }
}
