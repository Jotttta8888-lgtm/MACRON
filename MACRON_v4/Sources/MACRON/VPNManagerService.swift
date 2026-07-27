import Foundation

class VPNManagerService: ObservableObject {
    static let shared = VPNManagerService()
    @Published var isConnected = false
    @Published var currentIP = "Desconocida"
    
    func connect(vpnName: String) {
        let script = "tell application \\\"System Events\\\" to tell current location of network preferences to connect service \\\"\\(vpnName)\\\""
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        try? task.run()
        isConnected = true
        NotificationService.shared.send(title: "MACRON VPN", body: "Conectando a: " + vpnName)
    }
    
    func disconnect(vpnName: String) {
        let script = "tell application \\\"System Events\\\" to tell current location of network preferences to disconnect service \\\"\\(vpnName)\\\""
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        try? task.run()
        isConnected = false
        NotificationService.shared.send(title: "MACRON VPN", body: "Desconectado de: " + vpnName)
    }
    
    func fetchPublicIP(completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://api.ipify.org") else { return }
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            let ip = String(data: data ?? Data(), encoding: .utf8) ?? "Error"
            DispatchQueue.main.async {
                self.currentIP = ip
                completion(ip)
            }
        }
        task.resume()
    }
}
