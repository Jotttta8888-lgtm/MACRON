import Foundation

class HealthTrackerService: ObservableObject {
    static let shared = HealthTrackerService()
    @Published var entries: [HealthEntry] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/health.json"
    
    struct HealthEntry: Identifiable, Codable {
        var id = UUID()
        let date: Date
        let weight: Double?
        let sleepHours: Double?
        let waterGlasses: Int?
        let exerciseMinutes: Int?
        let mood: String?
    }
    
    func addEntry(weight: Double? = nil, sleep: Double? = nil, water: Int? = nil, exercise: Int? = nil, mood: String? = nil) {
        let entry = HealthEntry(date: Date(), weight: weight, sleepHours: sleep, waterGlasses: water, exerciseMinutes: exercise, mood: mood)
        entries.insert(entry, at: 0)
        save()
        NotificationService.shared.send(title: "MACRON Health", body: "Registro de salud guardado")
    }
    
    func getWeeklyReport() -> String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = entries.filter { $0.date >= weekAgo }
        let weights = recent.compactMap { $0.weight }
        let sleeps = recent.compactMap { $0.sleepHours }
        let avgWeight = weights.isEmpty ? 0 : weights.reduce(0, +) / Double(weights.count)
        let avgSleep = sleeps.isEmpty ? 0 : sleeps.reduce(0, +) / Double(sleeps.count)
        let totalWater = recent.compactMap { $0.waterGlasses }.reduce(0, +)
        return "Semana: Peso \(String(format: "%.1f", avgWeight))kg, Sueno \(String(format: "%.1f", avgSleep))h, Agua \(totalWater) vasos"
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(entries)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([HealthEntry].self, from: data) else { return }
        entries = decoded
    }
}
