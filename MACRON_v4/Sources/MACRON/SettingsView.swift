import SwiftUI

struct MACRONSettingsView: View {
    @ObservedObject var brainState: BrainState
    @AppStorage("macron_wakeWord") private var wakeWord = "Hey Macron"
    @AppStorage("macron_useReasoning") private var useReasoning = true
    @AppStorage("macron_useBiometrics") private var useBiometrics = true
    @AppStorage("macron_useProactive") private var useProactive = true
    @AppStorage("macron_darkMode") private var darkMode = true
    @AppStorage("macron_ttsRate") private var ttsRate: Double = 0.5
    
    var body: some View {
        Form {
            Section("Brain") {
                Toggle("Razonamiento (Chain-of-Thought)", isOn: $useReasoning)
                    .onChange(of: useReasoning) { _, newValue in MACRONBrain.shared.useReasoning = newValue }
                Toggle("Biometricos por voz", isOn: $useBiometrics)
                    .onChange(of: useBiometrics) { _, newValue in MACRONBrain.shared.useBiometrics = newValue }
                Toggle("IA Proactiva", isOn: $useProactive)
                    .onChange(of: useProactive) { _, newValue in MACRONBrain.shared.useProactive = newValue }
            }
            Section("Voz") {
                TextField("Wake Word", text: $wakeWord)
                    .onChange(of: wakeWord) { _, newValue in MACRONBrain.shared.wakeWord = newValue }
                Slider(value: $ttsRate, in: 0.3...0.8, step: 0.05) {
                    Text("Velocidad TTS: " + String(Int(ttsRate * 100)) + "%")
                }
            }
            Section("Apariencia") {
                Toggle("Modo Oscuro", isOn: $darkMode)
            }
            Section("Sistema") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("4.9.3 (169 features)")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Plataforma")
                    Spacer()
                    Text("macOS 14+ · Apple Silicon")
                        .foregroundColor(.secondary)
                }
                Button("Resetear Voiceprint") {
                    VoiceBiometrics.shared.resetProfile()
                }
                .foregroundColor(.red)
                Button("Limpiar Log Proactivo") {
                    ProactiveAI.shared.resetLog()
                }
                .foregroundColor(.orange)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}
