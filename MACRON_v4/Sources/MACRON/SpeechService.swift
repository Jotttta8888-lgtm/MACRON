import SwiftUI
import Speech
import AVFoundation

@MainActor
class SpeechService: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    
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
    
    func startRecording() async {
        guard await requestPermissions() else {
            errorMessage = "Se necesitan permisos de reconocimiento de voz"
            return
        }
        
        do {
            // Cancelar tarea previa
            recognitionTask?.cancel()
            recognitionTask = nil
            
            // Crear request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                errorMessage = "No se pudo crear el request de reconocimiento"
                return
            }
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.requiresOnDeviceRecognition = true // Privacidad: solo local
            
            // Iniciar reconocimiento
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    Task { @MainActor in
                        self.transcript = result.bestTranscription.formattedString
                    }
                }
                if error != nil || result?.isFinal == true {
                    Task { @MainActor in
                        self.stopRecording()
                    }
                }
            }
            
            // Configurar audio engine (macOS: sin AVAudioSession)
            audioEngine = AVAudioEngine()
            let inputNode = audioEngine!.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine?.prepare()
            try audioEngine?.start()
            
            isRecording = true
            errorMessage = nil
            
        } catch {
            errorMessage = "Error iniciando grabación: \(error.localizedDescription)"
            stopRecording()
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
    
    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            transcript = ""
            await startRecording()
        }
    }
}
