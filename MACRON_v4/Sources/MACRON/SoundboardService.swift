import Foundation
import AVFoundation

class SoundboardService: ObservableObject {
    static let shared = SoundboardService()
    @Published var sounds: [SoundItem] = []
    private var player: AVAudioPlayer?
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/soundboard.json"
    
    struct SoundItem: Identifiable, Codable {
        var id = UUID()
        let name: String
        let filePath: String
        let hotkey: String
    }
    
    func addSound(name: String, filePath: String, hotkey: String) {
        let sound = SoundItem(name: name, filePath: filePath, hotkey: hotkey)
        sounds.append(sound)
        save()
    }
    
    func playSound(_ name: String) {
        guard let sound = sounds.first(where: { $0.name == name }),
              let url = URL(string: sound.filePath) else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Error reproduciendo sonido: \(error)")
        }
    }
    
    func playBuiltin(_ type: String) {
        let systemSounds: [String: String] = [
            "applause": "/System/Library/Sounds/Glass.aiff",
            "error": "/System/Library/Sounds/Basso.aiff",
            "suspense": "/System/Library/Sounds/Ping.aiff",
            "success": "/System/Library/Sounds/Purr.aiff"
        ]
        guard let path = systemSounds[type] else { return }
        let url = URL(fileURLWithPath: path)
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Error: \(error)")
        }
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(sounds)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([SoundItem].self, from: data) else { return }
        sounds = decoded
    }
}
