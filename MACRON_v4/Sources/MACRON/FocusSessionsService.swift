import Foundation

class FocusSessionsService: ObservableObject {
    static let shared = FocusSessionsService()
    @Published var sessions: [FocusSession] = []
    @Published var currentSession: FocusSession?
    @Published var isActive = false
    private var timer: Timer?
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/focus_sessions.json"
    
    struct FocusSession: Identifiable, Codable {
        var id = UUID()
        let startTime: Date
        var endTime: Date?
        var durationMinutes: Int
        var blockedApps: [String]
        var completed: Bool = false
    }
    
    func startSession(minutes: Int, blockApps: [String] = []) {
        let session = FocusSession(startTime: Date(), endTime: nil, durationMinutes: minutes, blockedApps: blockApps)
        currentSession = session
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkSession()
        }
        NotificationService.shared.send(title: "MACRON Focus", body: "Sesion iniciada: " + String(minutes) + " min")
    }
    
    func stopSession() {
        timer?.invalidate()
        if var session = currentSession {
            session.endTime = Date()
            session.completed = false
            sessions.append(session)
            save()
        }
        isActive = false
        currentSession = nil
        NotificationService.shared.send(title: "MACRON Focus", body: "Sesion detenida")
    }
    
    func completeSession() {
        timer?.invalidate()
        if var session = currentSession {
            session.endTime = Date()
            session.completed = true
            sessions.append(session)
            save()
        }
        isActive = false
        currentSession = nil
        NotificationService.shared.send(title: "MACRON Focus", body: "¡Sesion completada!")
    }
    
    private func checkSession() {
        guard let session = currentSession else { return }
        let elapsed = Date().timeIntervalSince(session.startTime) / 60
        if Int(elapsed) >= session.durationMinutes {
            completeSession()
        }
    }
    
    func getDailyStats() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let todaySessions = sessions.filter { Calendar.current.isDate($0.startTime, inSameDayAs: today) }
        let totalMinutes = todaySessions.reduce(0) { $0 + ($1.durationMinutes) }
        let completed = todaySessions.filter { $0.completed }.count
        return "Hoy: " + String(totalMinutes) + " min, " + String(completed) + " completadas"
    }
    
    func getWeeklyStats() -> String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekSessions = sessions.filter { $0.startTime >= weekAgo }
        let totalMinutes = weekSessions.reduce(0) { $0 + ($1.durationMinutes) }
        return "Semana: " + String(totalMinutes) + " minutos de enfoque"
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(sessions)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) else { return }
        sessions = decoded
    }
}
