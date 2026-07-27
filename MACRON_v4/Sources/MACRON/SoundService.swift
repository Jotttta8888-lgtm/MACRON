import Foundation
import AppKit

class SoundService {
    static let shared = SoundService()
    func playSuccess() { NSSound(named: "Glass")?.play() }
    func playError() { NSSound(named: "Basso")?.play() }
    func playClick() { NSSound(named: "Tink")?.play() }
    func playWake() { NSSound(named: "Ping")?.play() }
}
