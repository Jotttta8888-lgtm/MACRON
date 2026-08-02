import Foundation

public actor AutonomousEngine {
    public static let shared = AutonomousEngine()
    private init() {
        Task {
            await patternStore.load()
            await routineStore.load()
        }
    }
    
    private enum Config {
        static let sessionThreshold = 2
        static let cooldownMinutes: Double = 5
        static let inactivityTimeoutMinutes: Double = 10
        static let thinkIntervalSeconds: UInt64 = 10
        static let systemCommands: Set<String> = [
            "modo autonomo", "desactivar autonomia", "modo manual",
            "estadisticas", "stats", "mi uso", "rutina", "rutinas",
            "habitos", "dashboard", "estado", "status", "plugins",
            "lista plugins", "diagnostico", "health", "servicios",
            "traduce", "translate", "borra memoria", "olvida todo",
            "reset memoria", "que recuerdas", "mi memoria", "contexto actual"
        ]
    }
    
    private enum State { case idle, learning, cooldown }
    private var state: State = .idle
    private var isRunning = false
    private var thoughtTask: Task<Void, Never>?
    private var sessionInteractions: Int = 0
    private var lastUserActivity: Date = Date.distantPast
    private var lastSuggestionTime: Date = Date.distantPast
    private var lastSuggestedHour: Int = -1
    private var thoughtCycles: Int = 0
    private let patternStore = HourlyPatternStore()
    private let routineStore = RoutineStore()
    
    public func startThinking() {
        guard !isRunning else { return }
        isRunning = true
        thoughtTask = Task {
            while !Task.isCancelled {
                await self.think()
                try? await Task.sleep(nanoseconds: Config.thinkIntervalSeconds * 1_000_000_000)
            }
        }
    }
    
    public func stopThinking() {
        isRunning = false
        thoughtTask?.cancel()
        thoughtTask = nil
    }
    
    public func resetSession() {
        sessionInteractions = 0
        state = .idle
        lastSuggestedHour = -1
    }
    
    public func recordInteraction(text: String) async -> String? {
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())
        lastUserActivity = Date()
        await patternStore.increment(hour: hour)
        if !isSystemCommand(text) {
            await routineStore.record(command: text, hour: hour, weekday: weekday)
            sessionInteractions += 1
        }
        return await evaluateProactivity(hour: hour)
    }
    
    public func evaluateProactivityOnly() async -> String? {
        let hour = Calendar.current.component(.hour, from: Date())
        return await evaluateProactivity(hour: hour)
    }
    
    public func countInteraction(text: String) async {
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())
        lastUserActivity = Date()
        await patternStore.increment(hour: hour)
        if !isSystemCommand(text) {
            await routineStore.record(command: text, hour: hour, weekday: weekday)
            sessionInteractions += 1
        }
    }
    
    private func evaluateProactivity(hour: Int) async -> String? {
        let minutesSinceLastSuggestion = Date().timeIntervalSince(lastSuggestionTime) / 60
        guard minutesSinceLastSuggestion >= Config.cooldownMinutes else { return nil }
        guard hour != lastSuggestedHour else { return nil }
        guard sessionInteractions >= Config.sessionThreshold else { return nil }
        let count = await patternStore.count(for: hour)
        guard count >= Config.sessionThreshold else { return nil }
        let minutesSinceActivity = Date().timeIntervalSince(lastUserActivity) / 60
        guard minutesSinceActivity < 2 else { return nil }
        lastSuggestionTime = Date()
        lastSuggestedHour = hour
        state = .cooldown
        return generateSuggestion(for: hour)
    }
    
    private func generateSuggestion(for hour: Int) -> String {
        if hour >= 8 && hour <= 10 {
            return "Buenos dias. Quieres que revise tu calendario o emails?"
        } else if hour >= 13 && hour <= 15 {
            return "Noto que sueles interactuar a esta hora. Necesitas algo habitual?"
        } else if hour >= 18 && hour <= 20 {
            return "Buenas tardes. Algo en lo que pueda ayudarte?"
        } else {
            return "Noto que sueles interactuar a esta hora. Necesitas algo habitual?"
        }
    }
    
    private func think() async {
        thoughtCycles += 1
        let minutesSinceLastActivity = Date().timeIntervalSince(lastUserActivity) / 60
        guard minutesSinceLastActivity < Config.inactivityTimeoutMinutes else {
            state = .idle
            return
        }
        let hour = Calendar.current.component(.hour, from: Date())
        let count = await patternStore.count(for: hour)
        if sessionInteractions >= Config.sessionThreshold && count >= Config.sessionThreshold {
            state = .learning
        }
    }
    
    private func isSystemCommand(_ text: String) -> Bool {
        let lower = text.lowercased()
        return Config.systemCommands.contains { lower.contains($0) }
    }
    
    public func getSuggestedRoutine() async -> String {
        return await routineStore.getSuggestion()
    }
    
    public func getStats() async -> String {
        let topHour = await patternStore.topHour()
        var lines: [String] = []
        lines.append("Estadisticas de uso:")
        lines.append("• Interacciones esta sesion: \(sessionInteractions)")
        lines.append("• Hora mas activa: \(topHour?.key ?? 0):00 (\(topHour?.value ?? 0) veces)")
        lines.append("• Ultima actividad: \(lastUserActivity.formatted(date: .omitted, time: .shortened))")
        lines.append("• Rutinas aprendidas: \(await routineStore.count())")
        lines.append("• Ciclos de pensamiento: \(thoughtCycles)")
        lines.append("• Estado: \(String(describing: state))")
        return lines.joined(separator: "\n")
    }
}

fileprivate actor HourlyPatternStore {
    private var patterns: [Int: Int] = [:]
    private let savePath: URL
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = docs.appendingPathComponent("MACRON", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        savePath = dir.appendingPathComponent("hourly_patterns.json")
    }
    func increment(hour: Int) {
        patterns[hour, default: 0] += 1
        Task { save() }
    }
    func count(for hour: Int) -> Int { patterns[hour, default: 0] }
    func topHour() -> (key: Int, value: Int)? { patterns.max { $0.value < $1.value } }
    func load() {
        guard let data = try? Data(contentsOf: savePath),
              let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) else {
            patterns = [:]; return
        }
        patterns = decoded
    }
    func save() {
        guard let data = try? JSONEncoder().encode(patterns) else { return }
        try? data.write(to: savePath)
    }
}

fileprivate actor RoutineStore {
    struct Routine: Codable, Sendable {
        let command: String
        let hour: Int
        let weekday: Int
        var frequency: Int
        let createdAt: Date
    }
    private var routines: [Routine] = []
    private let savePath: URL
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = docs.appendingPathComponent("MACRON", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        savePath = dir.appendingPathComponent("routines_v6.json")
        Task { await load() }
    }
    func record(command: String, hour: Int, weekday: Int) {
        let normalized = command.lowercased().prefix(30).trimmingCharacters(in: .whitespaces)
        if let index = routines.firstIndex(where: {
            $0.command == normalized && $0.hour == hour && $0.weekday == weekday
        }) {
            routines[index].frequency += 1
        } else {
            routines.append(Routine(command: String(normalized), hour: hour, weekday: weekday,
                                    frequency: 1, createdAt: Date()))
        }
        Task { save() }
    }
    func getSuggestion() -> String {
        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)
        let currentWeekday = Calendar.current.component(.weekday, from: now)
        let matches = routines.filter {
            abs($0.hour - currentHour) <= 1 && $0.weekday == currentWeekday
        }.sorted { $0.frequency > $1.frequency }
        if let top = matches.first, top.frequency >= 3 {
            return "Rutina detectada: sueles '" + top.command + "' a esta hora. Ejecutar?"
        }
        return ""
    }
    func count() -> Int { routines.count }
    func load() {
        guard let data = try? Data(contentsOf: savePath),
              let decoded = try? JSONDecoder().decode([Routine].self, from: data) else {
            routines = []; return
        }
        routines = decoded
    }
    func save() {
        guard let data = try? JSONEncoder().encode(routines) else { return }
        try? data.write(to: savePath)
    }
}