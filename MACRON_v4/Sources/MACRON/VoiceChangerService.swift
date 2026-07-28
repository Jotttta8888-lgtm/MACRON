import Foundation
import AVFoundation

public class VoiceChangerService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastOutput: URL?
    
    func applyVoiceEffect(to audioURL: URL, effect: String, completion: @escaping (URL?) -> Void) {
        isProcessing = true
        Task {
            let asset = AVAsset(url: audioURL)
            let composition = AVMutableComposition()
            guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                isProcessing = false
                completion(nil)
                return
            }
            let sourceTracks = try? await asset.loadTracks(withMediaType: .audio)
            guard let sourceTrack = sourceTracks?.first else {
                isProcessing = false
                completion(nil)
                return
            }
            let assetDuration = try? await asset.load(.duration)
            try? audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: assetDuration ?? .zero), of: sourceTrack, at: .zero)
            
            let outputPath = NSHomeDirectory() + "/Documents/MACRON/voice_" + effect.lowercased() + "_" + String(Int(Date().timeIntervalSince1970)) + ".m4a"
            let outputURL = URL(fileURLWithPath: outputPath)
            
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
                isProcessing = false
                completion(nil)
                return
            }
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .m4a
            
            await exportSession.export()
            isProcessing = false
            lastOutput = outputURL
            completion(outputURL)
        }
    }
}
