import Foundation
import AVFoundation

class VoiceChangerService: ObservableObject {
    static let shared = VoiceChangerService()
    @Published var currentEffect = "Normal"
    @Published var isProcessing = false
    
    let effects = ["Normal", "Robot", "Deep", "Echo", "Chipmunk", "Alien"]
    
    func applyEffect(_ effect: String, to audioPath: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: audioPath) else { completion(nil); return }
        isProcessing = true
        let asset = AVAsset(url: url)
        let composition = AVMutableComposition()
        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid),
              let sourceTrack = asset.tracks(withMediaType: .audio).first else {
            isProcessing = false
            completion(nil)
            return
        }
        try? audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: sourceTrack, at: .zero)
        
        let outputPath = NSHomeDirectory() + "/Documents/MACRON/voice_" + effect.lowercased() + "_" + String(Int(Date().timeIntervalSince1970)) + ".m4a"
        let outputURL = URL(fileURLWithPath: outputPath)
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            isProcessing = false
            completion(nil)
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.exportAsynchronously {
            self.isProcessing = false
            completion(outputPath)
        }
    }
    
    func previewEffect(_ effect: String) {
        let descriptions: [String: String] = [
            "Robot": "Voz sintetizada con tono metalico",
            "Deep": "Voz grave y lenta",
            "Echo": "Voz con reverberacion",
            "Chipmunk": "Voz aguda y rapida",
            "Alien": "Voz distorsionada extraterrestre"
        ]
        NotificationService.shared.send(title: "MACRON Voice", body: descriptions[effect] ?? "Efecto normal")
    }
}
