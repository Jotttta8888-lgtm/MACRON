import Foundation
import AVFoundation

public actor VoiceCloneService {
    public static let shared = VoiceCloneService()
    
    private var audioRecorder: AVAudioRecorder?
    private var isRecordingFlag = false
    private let sampleDir: URL
    
    private var trainedPitch: Float = 0.0
    private var trainedRate: Float = 0.5
    private var isTrainedFlag = false
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        sampleDir = docs.appendingPathComponent("MACRON/VoiceClone", isDirectory: true)
        try? FileManager.default.createDirectory(at: sampleDir, withIntermediateDirectories: true)
        Task { await loadTrainedProfile() }
    }
    
    public var isRecording: Bool { isRecordingFlag }
    public var isTrained: Bool { isTrainedFlag }
    
    public func getTrainingStatus() -> String {
        let samples = (try? FileManager.default.contentsOfDirectory(at: sampleDir, includingPropertiesForKeys: nil)) ?? []
        let wavs = samples.filter { $0.pathExtension == "wav" }
        if wavs.count >= 3 {
            return "✅ Voice Clone entrenado con \(wavs.count) muestras."
        } else {
            return "🎙️ Faltan \(3 - wavs.count) muestras. Di 'Grabar muestra 1' para empezar."
        }
    }
    
    public func startRecording(sampleIndex: Int) -> String {
        guard !isRecordingFlag else {
            return "❌ Ya estoy grabando. Di 'Detener grabacion' primero."
        }
        
        let url = sampleDir.appendingPathComponent("sample_\(sampleIndex).wav")
        try? FileManager.default.removeItem(at: url)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.prepareToRecord()
            let success = audioRecorder?.record() ?? false
            
            if success {
                isRecordingFlag = true
                return "🎙️ Grabando muestra \(sampleIndex)... Di: 'La inteligencia artificial local es el futuro de la privacidad.' Luego escribe 'Detener grabacion'."
            } else {
                return "❌ El grabador no pudo iniciar. Verifica permisos de micrófono en Ajustes del Sistema → Privacidad y Seguridad → Micrófono."
            }
        } catch {
            return "❌ Error al iniciar grabación: " + error.localizedDescription
        }
    }
    
    public func stopRecording() -> String {
        guard isRecordingFlag else {
            return "❌ No estaba grabando."
        }
        
        audioRecorder?.stop()
        isRecordingFlag = false
        
        if let url = audioRecorder?.url {
            analyzeSample(url: url)
        }
        audioRecorder = nil
        
        let samples = (try? FileManager.default.contentsOfDirectory(at: sampleDir, includingPropertiesForKeys: nil)) ?? []
        let wavs = samples.filter { $0.pathExtension == "wav" }
        
        if wavs.count >= 3 {
            buildVoiceProfile()
            return "✅ Muestra guardada. Voice Clone LISTO — tengo \(wavs.count) muestras. Di 'Activa voice clone'."
        } else {
            return "✅ Muestra guardada. Faltan \(3 - wavs.count) muestras más. Di 'Grabar muestra \(wavs.count + 1)'."
        }
    }
    
    private func analyzeSample(url: URL) {
        guard let file = try? AVAudioFile(forReading: url) else { return }
        let format = file.processingFormat
        let frameCount = UInt32(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        try? file.read(into: buffer)
        guard let data = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        var pitches: [Float] = []
        let sampleRate = Float(format.sampleRate)
        let windowSize = 2048
        let hopSize = 512
        
        for start in stride(from: 0, to: frameLength - windowSize, by: hopSize) {
            var maxCorr: Float = 0
            var bestLag = 0
            for lag in 20..<windowSize/2 {
                var autocorr: Float = 0
                for i in 0..<windowSize-lag {
                    autocorr += data[start + i] * data[start + i + lag]
                }
                if autocorr > maxCorr {
                    maxCorr = autocorr
                    bestLag = lag
                }
            }
            if bestLag > 0 {
                let pitch = sampleRate / Float(bestLag)
                if pitch > 80 && pitch < 400 {
                    pitches.append(pitch)
                }
            }
        }
        
        if !pitches.isEmpty {
            let avgPitch = pitches.reduce(0, +) / Float(pitches.count)
            trainedPitch = (trainedPitch == 0) ? avgPitch : (trainedPitch + avgPitch) / 2
        }
    }
    
    private func buildVoiceProfile() {
        let samples = (try? FileManager.default.contentsOfDirectory(at: sampleDir, includingPropertiesForKeys: nil)) ?? []
        let wavs = samples.filter { $0.pathExtension == "wav" }
        
        var totalDuration: TimeInterval = 0
        for url in wavs {
            guard let file = try? AVAudioFile(forReading: url) else { continue }
            totalDuration += Double(file.length) / file.processingFormat.sampleRate
        }
        
        let avgDuration = totalDuration / Double(max(wavs.count, 1))
        trainedRate = Float(min(max(0.4 + (avgDuration / 20.0), 0.3), 0.8))
        isTrainedFlag = true
        
        let profile = [
            "pitch": trainedPitch,
            "rate": trainedRate,
            "trained": true
        ] as [String: Any]
        let profileURL = sampleDir.appendingPathComponent("profile.plist")
        (profile as NSDictionary).write(to: profileURL, atomically: true)
    }
    
    private func loadTrainedProfile() {
        let profileURL = sampleDir.appendingPathComponent("profile.plist")
        guard let dict = NSDictionary(contentsOf: profileURL) as? [String: Any] else { return }
        trainedPitch = dict["pitch"] as? Float ?? 0
        trainedRate = dict["rate"] as? Float ?? 0.5
        isTrainedFlag = dict["trained"] as? Bool ?? false
    }
    
    public func speakWithClonedVoice(text: String) async {
        guard isTrainedFlag else { return }
        
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.es-MX.Paulina")
        utterance.rate = trainedRate
        utterance.pitchMultiplier = calculatePitchMultiplier()
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        
        while synthesizer.isSpeaking {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    private func calculatePitchMultiplier() -> Float {
        let basePitch: Float = 200.0
        guard trainedPitch > 0 else { return 1.0 }
        let ratio = trainedPitch / basePitch
        return min(max(ratio, 0.5), 2.0)
    }
    
    public func deleteVoiceProfile() {
        try? FileManager.default.removeItem(at: sampleDir)
        try? FileManager.default.createDirectory(at: sampleDir, withIntermediateDirectories: true)
        isTrainedFlag = false
        trainedPitch = 0
        trainedRate = 0.5
    }
}
