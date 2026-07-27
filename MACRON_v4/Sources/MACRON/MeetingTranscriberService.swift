import Foundation
import AVFoundation

class MeetingTranscriberService: ObservableObject {
    static let shared = MeetingTranscriberService()
    @Published var isRecording = false
    @Published var transcript: [TranscriptLine] = []
    private var audioRecorder: AVAudioRecorder?
    private let recordingsPath = NSHomeDirectory() + "/Documents/MACRON/recordings"
    
    struct TranscriptLine: Identifiable, Codable {
        var id = UUID()
        let timestamp: String
        let speaker: String
        let text: String
    }
    
    func startRecording() {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: recordingsPath, withIntermediateDirectories: true)
        let path = recordingsPath + "/meeting_\(Int(Date().timeIntervalSince1970)).m4a"
        let url = URL(fileURLWithPath: path)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            NotificationService.shared.send(title: "MACRON Transcriber", body: "Grabacion iniciada")
        } catch {
            print("Error grabando: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        NotificationService.shared.send(title: "MACRON Transcriber", body: "Grabacion detenida")
    }
    
    func addTranscriptLine(speaker: String, text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let line = TranscriptLine(timestamp: formatter.string(from: Date()), speaker: speaker, text: text)
        transcript.append(line)
    }
    
    func generateSummary() -> String {
        let texts = transcript.map { "[\($0.timestamp)] \($0.speaker): \($0.text)" }
        return texts.joined(separator: "\\n")
    }
    
    func exportTranscript() -> String {
        let summary = generateSummary()
        let path = recordingsPath + "/transcript_\(Int(Date().timeIntervalSince1970)).txt"
        try? summary.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }
}
