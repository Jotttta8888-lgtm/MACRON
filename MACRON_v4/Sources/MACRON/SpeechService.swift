import SwiftUI
import Speech
import AVFoundation

@MainActor
class SpeechService: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var errorMessage: String?
    @Published var lastError: String?
    @Published var consecutiveFailures = 0
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    private let maxConsecutiveFailures = 3
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    }
    
    func requestPermissions() async -> Bool {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        if speechStatus == .notDetermined {
            await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { _ in
                    continuation.resume()
                }
            }
        }
        return SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    func startRecording() async -> Bool {
        guard await requestPermissions() else {
            lastError = "Permisos de reconocimiento de voz denegados"
            consecutiveFailures += 1
            return false
        }
        
        do {
            cleanup()
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                lastError = "No se pudo crear el request de reconocimiento"
                consecutiveFailures += 1
                return false
            }
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.requiresOnDeviceRecognition = true
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    Task { @MainActor in
                        self.transcript = result.bestTranscription.formattedString
                    }
                }
                if let error = error {
                    Task { @MainActor in
                        self.lastError = "Error reconocimiento: \\(error.localizedDescription)"
                        self.stopRecording()
                    }
                } else if result?.isFinal == true {
                    Task { @MainActor in
                        self.stopRecording()
                    }
                }
            }
            
            audioEngine = AVAudioEngine()
            let inputNode = audioEngine!.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            
            audioEngine?.prepare()
            try audioEngine?.start()
            
            isRecording = true
            errorMessage = nil
            lastError = nil
            consecutiveFailures = 0
            return true
            
        } catch {
            lastError = "Error iniciando grabacion: \\(error.localizedDescription)"
            consecutiveFailures += 1
            cleanup()
            return false
        }
    }
    
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
    
    func cleanup() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    func restartRecording() async -> Bool {
        stopRecording()
        try? await Task.sleep(nanoseconds: 800_000_000)
        let success = await startRecording()
        if !success {
            print("[SpeechService] Fallo reinicio #\\(consecutiveFailures)")
        }
        return success
    }
    
    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            transcript = ""
            _ = await startRecording()
        }
    }
    
    var isHealthy: Bool {
        consecutiveFailures < maxConsecutiveFailures
    }
}
