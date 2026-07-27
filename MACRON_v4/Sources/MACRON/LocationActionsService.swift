import Foundation
import CoreWLAN

class LocationActionsService: ObservableObject {
    static let shared = LocationActionsService()
    @Published var currentNetwork = ""
    @Published var locationContext = "Desconocido"
    
    private let knownNetworks = [
        "Casa": "home",
        "Home": "home",
        "Oficina": "work",
        "Office": "work",
        "Starbucks": "cafe"
    ]
    
    func checkLocation() {
        let client = CWWiFiClient.shared()
        guard let interface = client.interface() else { return }
        guard let ssid = interface.ssid() else {
            currentNetwork = "Sin WiFi"
            return
        }
        currentNetwork = ssid
        let context = knownNetworks.first { ssid.contains($0.key) }?.value ?? "otro"
        locationContext = context
        
        if context == "home" {
            NotificationService.shared.send(title: "MACRON", body: "Bienvenido a casa")
        } else if context == "work" {
            NotificationService.shared.send(title: "MACRON", body: "Llegaste a la oficina")
        }
    }
}
