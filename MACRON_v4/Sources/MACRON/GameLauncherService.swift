import Foundation
import AppKit

class GameLauncherService: ObservableObject {
    static let shared = GameLauncherService()
    @Published var games: [Game] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/games.json"
    
    struct Game: Identifiable, Codable {
        var id = UUID()
        let name: String
        let platform: String
        let launchPath: String
        var playTimeMinutes: Int = 0
        var lastPlayed: Date?
    }
    
    func scanSteamGames() {
        let steamPath = NSHomeDirectory() + "/Library/Application Support/Steam/steamapps"
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: steamPath) else { return }
        for file in files where file.hasPrefix("appmanifest_") {
            let name = file.replacingOccurrences(of: "appmanifest_", with: "").replacingOccurrences(of: ".acf", with: "")
            let game = Game(name: "Steam App " + name, platform: "Steam", launchPath: "steam://run/" + name)
            if !games.contains(where: { $0.name == game.name }) {
                games.append(game)
            }
        }
        save()
    }
    
    func launchGame(_ game: Game) {
        if let url = URL(string: game.launchPath) {
            NSWorkspace.shared.open(url)
        }
        if let idx = games.firstIndex(where: { $0.id == game.id }) {
            games[idx].lastPlayed = Date()
        }
        NotificationService.shared.send(title: "MACRON Games", body: "Lanzando: " + game.name)
    }
    
    func addPlayTime(gameId: UUID, minutes: Int) {
        guard let idx = games.firstIndex(where: { $0.id == gameId }) else { return }
        games[idx].playTimeMinutes += minutes
        save()
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(games)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([Game].self, from: data) else { return }
        games = decoded
    }
}
