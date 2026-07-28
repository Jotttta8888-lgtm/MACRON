import Foundation
import AVFoundation

class VideoConverterService: ObservableObject {
    static let shared = VideoConverterService()
    @Published var isConverting = false
    @Published var progress = 0.0
    
    func convert(inputPath: String, outputFormat: String, completion: @escaping (String?) -> Void) {
        let inputURL = URL(fileURLWithPath: inputPath)
        let outputPath = inputPath.replacingOccurrences(of: ".\\w+$", with: "." + outputFormat, options: .regularExpression)
        let outputURL = URL(fileURLWithPath: outputPath)
        
        let asset = AVAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = outputFormat == "mp4" ? .mp4 : .mov
        isConverting = true
        progress = 0.0
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.progress = Double(exportSession.progress)
        }
        
        exportSession.exportAsynchronously {
            timer.invalidate()
            self.isConverting = false
            self.progress = 1.0
            completion(outputPath)
        }
    }
    
    func extractAudio(from videoPath: String, completion: @escaping (String?) -> Void) {
        let inputURL = URL(fileURLWithPath: videoPath)
        let outputPath = videoPath.replacingOccurrences(of: ".\\w+$", with: ".m4a", options: .regularExpression)
        let outputURL = URL(fileURLWithPath: outputPath)
        
        let asset = AVAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(nil)
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        isConverting = true
        exportSession.exportAsynchronously {
            self.isConverting = false
            completion(outputPath)
        }
    }
    
    func compressVideo(inputPath: String, quality: String = "medium", completion: @escaping (String?) -> Void) {
        let preset = quality == "high" ? AVAssetExportPresetHighestQuality : (quality == "low" ? AVAssetExportPresetLowQuality : AVAssetExportPresetMediumQuality)
        let inputURL = URL(fileURLWithPath: inputPath)
        let outputPath = inputPath.replacingOccurrences(of: ".", with: "_compressed.", options: .backwards)
        let outputURL = URL(fileURLWithPath: outputPath)
        
        let asset = AVAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            completion(nil)
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        isConverting = true
        exportSession.exportAsynchronously {
            self.isConverting = false
            completion(outputPath)
        }
    }
}
