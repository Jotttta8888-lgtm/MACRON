import Foundation

class SmartNotificationsService: ObservableObject {
    static let shared = SmartNotificationsService()
    @Published var isFiltering = true
    
    let allowedApps = ["Mail", "Messages", "Calendar", "FaceTime", "MACRON"]
    let blockedApps = ["Twitter", "Instagram", "TikTok", "YouTube", "Reddit"]
    
    func shouldShow(bundleId: String) -> Bool {
        if !isFiltering { return true }
        let lower = bundleId.lowercased()
        if blockedApps.contains(where: { lower.contains($0.lowercased()) }) { return false }
        return true
    }
    
    func toggleFiltering() {
        isFiltering.toggle()
        NotificationService.shared.send(title: "MACRON", body: isFiltering ? "Filtro activado" : "Filtro desactivado")
    }
}
