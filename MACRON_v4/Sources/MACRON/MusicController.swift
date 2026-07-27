import Foundation

class MusicController: ObservableObject {
    static let shared = MusicController()
    @Published var currentTrack = "Nada reproduciendo"
    @Published var isPlaying = false
    @Published var playerApp = "Ninguno"
    
    func runScript(_ source: String) -> String? {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&errorInfo)
        if let error = errorInfo { print("[Music] Error: " + String(describing: error)); return nil }
        return result.stringValue
    }
    
    func updateStatus() {
        if let track = runScript("tell application \"Spotify\" to return name of current track & \" | \" & artist of current track"), track.isEmpty == false {
            currentTrack = track
            isPlaying = true
            playerApp = "Spotify"
            return
        }
        if let track = runScript("tell application \"Music\" to return name of current track & \" | \" & artist of current track"), track.isEmpty == false {
            currentTrack = track
            isPlaying = true
            playerApp = "Apple Music"
            return
        }
        currentTrack = "Nada reproduciendo"
        isPlaying = false
        playerApp = "Ninguno"
    }
    
    func playPause() {
        if playerApp == "Spotify" {
            runScript("tell application \"Spotify\" to playpause")
        } else if playerApp == "Apple Music" {
            runScript("tell application \"Music\" to playpause")
        }
        updateStatus()
    }
    
    func nextTrack() {
        if playerApp == "Spotify" {
            runScript("tell application \"Spotify\" to next track")
        } else if playerApp == "Apple Music" {
            runScript("tell application \"Music\" to next track")
        }
        updateStatus()
    }
    
    func createPlaylist(name: String) {
        runScript("tell application \"Music\" to make new playlist with properties {name:\"" + name + "\"}")
        NotificationService.shared.send(title: "MACRON Music", body: "Playlist creada: " + name)
    }
}
