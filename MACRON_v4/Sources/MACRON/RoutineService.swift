import Foundation

public actor RoutineService {
    public static let shared = RoutineService()
    private init() { Task { await load() } }
    
    private var routines: [Routine] = []
    private let savePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("MACRON/routines.json")
    
    struct Routine: Codable, Sendable {
        let command: String
        let hour: Int
        let weekday: Int
        var frequency: Int
        let createdAt: Date
    }
    
    public func record(command: String, hour: Int, weekday: Int) async {
        // Normalizar comando
        let normalized = command.lowercased().prefix(30).trimmingCharacters(in: .whitespaces)
        
        if let index = routines.firstIndex(where: {
            $0.command == normalized && $0.hour == hour && $0.weekday == weekday
        }) {
            routines[index].frequency += 1
        } else {
            routines.append(Routine(
                command: String(normalized),
                hour: hour,
                weekday: weekday,
                frequency: 1,
                createdAt: Date()
            ))
        }
        
        await save()
    }
    
    public func getSuggestion() async -> String {
        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)
        let currentWeekday = Calendar.current.component(.weekday, from: now)
        
        // Buscar rutinas que coincidan con hora y dia actuales
        let matches = routines.filter {
            abs($0.hour - currentHour) <= 1 && $0.weekday == currentWeekday
        }.sorted { $0.frequency > $1.frequency }
        
        if let top = matches.first, top.frequency >= 3 {
            return "🔄 Rutina detectada: sueles '\(top.command)' a esta hora. ¿Ejecutar?"
        }
        
        return ""
    }
    
    public func count() async -> Int {
        return routines.count
    }
    
    public func list() async -> [String] {
        return routines.map { "[\($0.weekday)@\($0.hour):00] \($0.command) (x\($0.frequency))" }
    }
    
    private func save() async {
        do {
            let data = try JSONEncoder().encode(routines)
            try data.write(to: savePath)
        } catch {
            print("❌ Error guardando rutinas: \(error)")
        }
    }
    
    private func load() async {
        do {
            let data = try Data(contentsOf: savePath)
            routines = try JSONDecoder().decode([Routine].self, from: data)
        } catch {
            routines = []
        }
    }
}
