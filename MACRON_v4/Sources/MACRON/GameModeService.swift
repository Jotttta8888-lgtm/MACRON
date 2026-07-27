import Foundation
import AppKit

class GameModeService: ObservableObject {
    static let shared = GameModeService()
    @Published var isGameModeActive = false
    @Published var currentGame = ""
    
    private let gameApps = ["Steam", "Battle.net", "Epic Games", "League of Legends", "Valorant", "Minecraft", "Fortnite", "Counter-Strike"]
    private var timer: Timer?
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.checkGameMode()
        }
        checkGameMode()
    }
    
    private func checkGameMode() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let appName = frontApp.localizedName ?? ""
        let isGame = gameApps.contains { appName.contains($0) }
        
        DispatchQueue.main.async {
            if isGame && !self.isGameModeActive {
                self.isGameModeActive = true
                self.currentGame = appName
                NotificationService.shared.send(title: "MACRON Game Mode", body: "Modo juego activado: " + appName)
            } else if !isGame && self.isGameModeActive {
                self.isGameModeActive = false
                self.currentGame = ""
                NotificationService.shared.send(title: "MACRON Game Mode", body: "Modo juego desactivado")
            }
        }
    }
}
