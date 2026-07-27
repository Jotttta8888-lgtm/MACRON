import Foundation

class TravelPlannerService: ObservableObject {
    static let shared = TravelPlannerService()
    @Published var trips: [Trip] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/trips.json"
    
    struct Trip: Identifiable, Codable {
        var id = UUID()
        let destination: String
        let startDate: Date
        let endDate: Date
        var itinerary: [ItineraryItem] = []
        var packingList: [PackingItem] = []
    }
    
    struct ItineraryItem: Identifiable, Codable {
        var id = UUID()
        let day: Int
        let activity: String
        let time: String
    }
    
    struct PackingItem: Identifiable, Codable {
        var id = UUID()
        let name: String
        var isPacked: Bool = false
    }
    
    func createTrip(destination: String, start: Date, end: Date) {
        let trip = Trip(destination: destination, startDate: start, endDate: end)
        trips.append(trip)
        save()
        NotificationService.shared.send(title: "MACRON Travel", body: "Viaje a " + destination + " planificado")
    }
    
    func addItineraryItem(tripId: UUID, day: Int, activity: String, time: String) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        let item = ItineraryItem(day: day, activity: activity, time: time)
        trips[idx].itinerary.append(item)
        save()
    }
    
    func addPackingItem(tripId: UUID, name: String) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        let item = PackingItem(name: name)
        trips[idx].packingList.append(item)
        save()
    }
    
    func togglePacked(tripId: UUID, itemId: UUID) {
        guard let tIdx = trips.firstIndex(where: { $0.id == tripId }),
              let iIdx = trips[tIdx].packingList.firstIndex(where: { $0.id == itemId }) else { return }
        trips[tIdx].packingList[iIdx].isPacked.toggle()
        save()
    }
    
    func convertCurrency(amount: Double, from: String, to: String) -> String {
        let rates: [String: Double] = ["USD": 1.0, "EUR": 0.92, "GBP": 0.79, "JPY": 150.0, "COP": 3900.0, "MXN": 17.0]
        guard let fromRate = rates[from.uppercased()], let toRate = rates[to.uppercased()] else {
            return "Moneda no soportada"
        }
        let result = amount * (toRate / fromRate)
        return String(format: "%.2f %@ = %.2f %@", amount, from, result, to)
    }
    
    func getTimeZoneDifference(city: String) -> String {
        let zones: [String: String] = [
            "Nueva York": "America/New_York",
            "Londres": "Europe/London",
            "Tokio": "Asia/Tokyo",
            "Sydney": "Australia/Sydney",
            "Paris": "Europe/Paris"
        ]
        guard let zone = zones[city] else { return "Zona horaria desconocida" }
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: zone)
        formatter.dateFormat = "HH:mm"
        return city + ": " + formatter.string(from: Date())
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(trips)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([Trip].self, from: data) else { return }
        trips = decoded
    }
}
