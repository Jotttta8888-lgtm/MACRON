import SwiftUI
import AVFoundation

struct VoiceprintTrainerView: View {
    @State private var isRecording = false
    @State private var statusMessage = "Presiona Grabar para entrenar tu voiceprint"
    @State private var progress: Double = 0.0
    @State private var isTrained = VoiceBiometrics.shared.isTrained
    @State private var audioEngine = AVAudioEngine()
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isTrained ? "checkmark.shield.fill" : "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(isTrained ? .green : .accentColor)
            
            Text(isTrained ? "Voiceprint Entrenado" : "Voiceprint No Entrenado")
                .font(.title2.bold())
            
            Text(statusMessage)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if isRecording {
                ProgressView(value: progress, total: 5.0)
                    .progressViewStyle(.linear)
                    .padding(.horizontal, 40)
                Text("Grabando... " + String(format: "%.1f", 5.0 - progress) + "s")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack(spacing: 16) {
                Button(action: startTraining) {
                    Label(isRecording ? "Grabando..." : "Grabar Voiceprint", systemImage: "mic.fill")
                        .frame(minWidth: 140)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(isRecording)
                
                Button(action: resetVoiceprint) {
                    Label("Borrar", systemImage: "trash")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!isTrained)
            }
            
            if isTrained {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("Autenticacion por voz activa")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 350)
    }
    
    private func startTraining() {
        guard !isRecording else { return }
        isRecording = true
        progress = 0.0
        statusMessage = "Lee en voz alta: Mi nombre es " + NSFullUserName() + " y este es mi Mac NEO"
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        var bufferData = Data()
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            let channelData = buffer.floatChannelData![0]
            let data = Data(bytes: channelData, count: Int(buffer.frameLength * 4))
            bufferData.append(data)
        }
        
        do {
            try audioEngine.start()
        } catch {
            statusMessage = "Error iniciando audio: " + error.localizedDescription
            isRecording = false
            return
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.1
            if progress >= 5.0 {
                timer.invalidate()
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(bufferData.count / 4)) else {
                    statusMessage = "Error creando buffer"
                    isRecording = false
                    return
                }
                
                VoiceBiometrics.shared.train(with: audioBuffer) { success in
                    DispatchQueue.main.async {
                        isTrained = success
                        statusMessage = success ? "Voiceprint entrenado exitosamente" : "Error entrenando voiceprint"
                        isRecording = false
                    }
                }
            }
        }
    }
    
    private func resetVoiceprint() {
        VoiceBiometrics.shared.resetProfile()
        isTrained = false
        statusMessage = "Voiceprint borrado. Presiona Grabar para reentrenar."
    }
}
