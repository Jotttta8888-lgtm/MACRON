import Foundation
import AppKit

class WakeWordService: NSObject, ObservableObject, NSSpeechRecognizerDelegate {
    @Published var isListening = false
    @Published var lastDetectedText = ""
    @Published var wakeWordDetected = false
    
    private var speechRecognizer: NSSpeechRecognizer?
    private let wakeWords = ["hey macron", "oye macron", "ok macron", "hola macron", "ey macron", "macron"]
    private var isProcessing = false
    
    override init() {
        super.init()
        print("[WakeWord] Servicio inicializado con NSSpeechRecognizer")
    }
    
    func startListening() {
        guard !isListening else {
            print("[WakeWord] Ya estaba escuchando")
            return
        }
        
        print("[WakeWord] Configurando NSSpeechRecognizer...")
        
        speechRecognizer = NSSpeechRecognizer()
        speechRecognizer?.delegate = self
        speechRecognizer?.commands = wakeWords
        speechRecognizer?.listensInForegroundOnly = false
        speechRecognizer?.blocksOtherRecognizers = true
        
        speechRecognizer?.startListening()
        isListening = true
        
        print("[WakeWord] ESCUCHANDO ACTIVAMENTE - di 'Hey MACRON'")
        print("[WakeWord] Comandos registrados: \\(wakeWords)")
    }
    
    func stopListening() {
        print("[WakeWord] Deteniendo...")
        speechRecognizer?.stopListening()
        speechRecognizer = nil
        isListening = false
    }
    
    func speechRecognizer(_ sender: NSSpeechRecognizer, didRecognizeCommand command: String) {
        print("[WakeWord] >>>>> DETECTADO: \\(command) <<<<<")
        triggerWakeWord()
    }
    
    private func triggerWakeWord() {
        guard !isProcessing else {
            print("[WakeWord] Ignorando - ya procesando")
            return
        }
        isProcessing = true
        wakeWordDetected = true
        
        NotificationCenter.default.post(name: .wakeWordDetected, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.wakeWordDetected = false
            self?.isProcessing = false
            print("[WakeWord] Listo para siguiente deteccion")
        }
    }
}
