import SwiftUI
import Speech
import AVFoundation

@MainActor
class VoiceActionService: ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var actionResults: [VoiceActionResponse] = []
    @Published var errorMessage: String?
    @Published var isProcessing = false
    @Published var isContinuousMode = false
    @Published var micStatus = "Listo"
    @Published var isMicHealthy: Bool = true
    
    private var speechService: SpeechService
    private var apiClient: MacronAPIClient
    private var continuousTask: Task<Void, Never>?
    private var lastTranscript = ""
    private var cycleCount = 0
    
    init(apiClient: MacronAPIClient) {
        self.apiClient = apiClient
        self.speechService = SpeechService()
    }
    
    func startVoiceAction(continuous: Bool = false) async {
        guard await speechService.requestPermissions() else {
            errorMessage = "Se necesitan permisos de microfono"
            micStatus = "Permisos denegados"
            isMicHealthy = false
            return
        }
        
        isContinuousMode = continuous
        transcript = ""
        lastTranscript = ""
        actionResults = []
        errorMessage = nil
        isListening = true
        cycleCount = 0
        micStatus = "Iniciando..."
        isMicHealthy = speechService.isHealthy
        
        if continuous {
            await runContinuousMode()
        } else {
            let ok = await speechService.startRecording()
            if ok {
                await monitorSingleRecording()
            } else {
                errorMessage = speechService.lastError
                isListening = false
                micStatus = "Error al iniciar"
                isMicHealthy = false
            }
        }
    }
    
    private func monitorSingleRecording() async {
        while speechService.isRecording {
            transcript = speechService.transcript
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        isListening = false
        micStatus = "Procesando..."
        let finalText = speechService.transcript
        
        if !finalText.isEmpty {
            await executeAction(text: finalText)
        }
        micStatus = "Listo"
    }
    
    private func runContinuousMode() async {
        while isContinuousMode {
            cycleCount += 1
            isMicHealthy = speechService.isHealthy
            
            guard isMicHealthy else {
                errorMessage = "Microfono fallo demasiadas veces. Deteniendo modo continuo."
                micStatus = "Microfono no disponible"
                isContinuousMode = false
                break
            }
            
            transcript = ""
            micStatus = "Ciclo #\(cycleCount): Escuchando..."
            
            let success = await speechService.restartRecording()
            
            guard success else {
                let err = speechService.lastError ?? "desconocido"
                micStatus = "Fallo ciclo #\(cycleCount): \(err)"
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                continue
            }
            
            var waitCount = 0
            while !speechService.isRecording && waitCount < 20 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                waitCount += 1
            }
            
            guard speechService.isRecording else {
                micStatus = "No se pudo iniciar grabacion"
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                continue
            }
            
            isListening = true
            micStatus = "Escuchando..."
            
            while speechService.isRecording && isContinuousMode {
                transcript = speechService.transcript
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            
            if !isContinuousMode { break }
            
            isListening = false
            let capturedText = speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !capturedText.isEmpty && capturedText != lastTranscript {
                lastTranscript = capturedText
                micStatus = "Procesando: \(capturedText)"
                await executeAction(text: capturedText)
                micStatus = "Listo - esperando siguiente comando"
                try? await Task.sleep(nanoseconds: 2_500_000_000)
            } else {
                micStatus = "Sin comando detectado"
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        micStatus = "Modo continuo detenido"
        speechService.stopRecording()
    }
    
    func stopVoiceAction() {
        isContinuousMode = false
        speechService.stopRecording()
        isListening = false
        continuousTask?.cancel()
        micStatus = "Detenido"
    }
    
    func toggleContinuousMode() {
        if isContinuousMode {
            stopVoiceAction()
        } else {
            continuousTask = Task {
                await startVoiceAction(continuous: true)
            }
        }
    }
    
    private func executeAction(text: String) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let result = try await apiClient.sendVoiceAction(text: text)
            actionResults.append(result)
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
}
