import Foundation
import AppKit
import ShazamKit

class MusicRecognitionService: ObservableObject {
    static let shared = MusicRecognitionService()
    @Published var history: [RecognizedSong] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/music_history.json"
    
    struct RecognizedSong: Identifiable, Codable {
        var id = UUID()
        let title: String
        let artist: String
        let album: String
        let timestamp: Date
    }
    
    func addToHistory(title: String, artist: String, album: String = "") {
        let song = RecognizedSong(title: title, artist: artist, album: album, timestamp: Date())
        history.insert(song, at: 0)
        if history.count > 100 { history.removeLast() }
        save()
        NotificationService.shared.send(title: "MACRON Music", body: "Reconocido: " + title + " - " + artist)
    }
    
    func createPlaylist() -> String {
        let unique = Array(Set(history.map { $0.title + " - " + $0.artist }))
        return unique.joined(separator: "\\n")
    }
    
    func searchOnAppleMusic(_ song: RecognizedSong) {
        let query = (song.title + " " + song.artist).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://music.apple.com/search?term=" + query) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(history)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([RecognizedSong].self, from: data) else { return }
        history = decoded
    }
}
