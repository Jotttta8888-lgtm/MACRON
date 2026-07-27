import Foundation
import AppKit

class PackageTrackerService: ObservableObject {
    static let shared = PackageTrackerService()
    @Published var packages: [Package] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/packages.json"
    
    struct Package: Identifiable, Codable {
        var id = UUID()
        let trackingNumber: String
        let carrier: String
        let description: String
        var status: String
        var lastUpdate: Date
    }
    
    func addPackage(tracking: String, carrier: String, description: String) {
        let pkg = Package(trackingNumber: tracking, carrier: carrier, description: description, status: "Registrado", lastUpdate: Date())
        packages.append(pkg)
        save()
        NotificationService.shared.send(title: "MACRON Tracker", body: "Paquete registrado: " + description)
    }
    
    func updateStatus(tracking: String, status: String) {
        guard let idx = packages.firstIndex(where: { $0.trackingNumber == tracking }) else { return }
        packages[idx].status = status
        packages[idx].lastUpdate = Date()
        save()
        NotificationService.shared.send(title: "MACRON Tracker", body: "Estado actualizado: " + status)
    }
    
    func getTrackingURL(_ package: Package) -> URL? {
        let urls: [String: String] = [
            "fedex": "https://www.fedex.com/apps/fedextrack/?tracknumbers=",
            "dhl": "https://www.dhl.com/en/express/tracking.html?AWB=",
            "usps": "https://tools.usps.com/go/TrackConfirmAction?tLabels=",
            "ups": "https://www.ups.com/track?tracknum="
        ]
        guard let base = urls[package.carrier.lowercased()] else { return nil }
        return URL(string: base + package.trackingNumber)
    }
    
    func openTrackingPage(_ package: Package) {
        if let url = getTrackingURL(package) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(packages)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([Package].self, from: data) else { return }
        packages = decoded
    }
}
