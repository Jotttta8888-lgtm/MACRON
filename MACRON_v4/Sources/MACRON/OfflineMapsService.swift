import Foundation
import AppKit
import Combine

class OfflineMapsService: ObservableObject {
    static let shared = OfflineMapsService()
    @Published var savedLocations: [SavedLocation] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/locations.json"
    
    struct SavedLocation: Identifiable, Codable {
        var id = UUID()
        let name: String
        let latitude: Double
        let longitude: Double
        let note: String
    }
    
    func saveLocation(name: String, lat: Double, lon: Double, note: String = "") {
        let loc = SavedLocation(name: name, latitude: lat, longitude: lon, note: note)
        savedLocations.append(loc)
        save()
        NotificationService.shared.send(title: "MACRON Maps", body: "Ubicacion guardada: " + name)
    }
    
    func searchLocation(query: String) -> String {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlStr = "https://www.google.com/maps/search/?api=1&query=" + encoded
        if let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
        return "Buscando: " + query
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(savedLocations)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) else { return }
        savedLocations = decoded
    }
}
