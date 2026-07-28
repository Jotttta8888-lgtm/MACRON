import Foundation
import Speech
import AVFoundation

public final class RealtimeTranscriber: NSObject, SFSpeechRecognizerDelegate, @unchecked Sendable {
    public static let shared = RealtimeTranscriber()
    public enum State: Equatable { case idle, listening, transcribing, error(String) }
    public private(set) var state: State = .idle { didSet { onStateChange?(state) } }
    public var onTranscript: ((String, Bool) -> Void)?
    public var onStateChange: ((State) -> Void)?
    private let recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.8
    private var lastSpeechTimestamp: Date = Date.distantPast
    private var currentBuffer: String = ""
    private let bufferQueue = DispatchQueue(label: "macron.transcriber")
    
    private override init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
        super.init()
        recognizer?.delegate = self
    }
    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in DispatchQueue.main.async { completion(status == .authorized) } }
    }
    public func startListening() {
        guard state == .idle else { return }
        guard let recognizer = recognizer, recognizer.isAvailable else { state = .error("Speech recognizer no disponible"); return }
        do {
            // macOS: no necesita AVAudioSession
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let request = recognitionRequest else { return }
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = true
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                self.bufferQueue.async {
                    if let error = error { DispatchQueue.main.async { self.state = .error(error.localizedDescription) }; return }
                    if let result = result {
                        let text = result.bestTranscription.formattedString
                        self.lastSpeechTimestamp = Date()
                        self.currentBuffer = text
                        DispatchQueue.main.async { self.onTranscript?(text, result.isFinal) }
                        if result.isFinal { self.finalizeUtterance() }
                    }
                }
            }
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in self.recognitionRequest?.append(buffer) }
            audioEngine.prepare()
            try audioEngine.start()
            state = .listening
            startSilenceTimer()
        } catch { state = .error(error.localizedDescription) }
    }
    public func stopListening() {
        audioEngine.stop(); audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio(); recognitionTask?.cancel()
        recognitionRequest = nil; recognitionTask = nil
        silenceTimer?.invalidate(); silenceTimer = nil
        state = .idle
    }
    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if Date().timeIntervalSince(self.lastSpeechTimestamp) > self.silenceThreshold && !self.currentBuffer.isEmpty { self.finalizeUtterance() }
        }
    }
    private func finalizeUtterance() {
        bufferQueue.async {
            let text = self.currentBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            self.currentBuffer = ""
            DispatchQueue.main.async { self.onTranscript?(text, true) }
        }
    }
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available { state = .error("Speech recognizer se volvio no disponible"); stopListening() }
    }
}
