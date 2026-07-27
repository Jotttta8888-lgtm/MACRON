import Foundation
import CoreWLAN

class WiFiAnalyzerService: ObservableObject {
    static let shared = WiFiAnalyzerService()
    @Published var networks: [WiFiNetwork] = []
    
    struct WiFiNetwork: Identifiable {
        let id = UUID()
        let ssid: String
        let rssi: Int
        let channel: Int
    }
    
    func scanNetworks() {
        let client = CWWiFiClient.shared()
        guard let iface = client.interface() else { return }
        do {
            let scan = try iface.scanForNetworks(withSSID: nil)
            networks = scan.map { net in
                WiFiNetwork(
                    ssid: net.ssid ?? "Hidden",
                    rssi: net.rssiValue,
                    channel: net.wlanChannel?.channelNumber ?? 0
                )
            }.sorted { $0.rssi > $1.rssi }
        } catch {
            print("Error escaneando WiFi: \(error)")
        }
    }
    
    func getCurrentNetwork() -> String {
        let client = CWWiFiClient.shared()
        guard let iface = client.interface(), let ssid = iface.ssid() else { return "No conectado" }
        return "Conectado a: " + ssid
    }
}
