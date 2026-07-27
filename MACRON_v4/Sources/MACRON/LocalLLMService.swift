import Foundation

class LocalLLMService: ObservableObject {
    static let shared = LocalLLMService()
    @Published var isModelLoaded = false
    @Published var modelName = "Ninguno"
    private var process: Process?
    private let modelPath = NSHomeDirectory() + "/Documents/MACRON/models"
    
    var availableModels: [String] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: modelPath) else { return [] }
        return files.filter { $0.hasSuffix(".gguf") || $0.hasSuffix(".mlmodelc") }
    }
    
    func ensureModelDirectory() {
        try? FileManager.default.createDirectory(atPath: modelPath, withIntermediateDirectories: true)
    }
    
    func startLocalServer(model: String) {
        ensureModelDirectory()
        let modelFile = modelPath + "/\(model)"
        guard FileManager.default.fileExists(atPath: modelFile) else {
            print("[LocalLLM] Modelo no encontrado: \(model)")
            return
        }
        let llamaServer = NSHomeDirectory() + "/Documents/MACRON/llama-server"
        let executable = FileManager.default.fileExists(atPath: llamaServer) ? llamaServer : "/usr/bin/python3"
        let args = FileManager.default.fileExists(atPath: llamaServer)
            ? ["-m", modelFile, "--host", "127.0.0.1", "--port", "5002", "-ngl", "99"]
            : ["-c", "print('LLM local no configurado')"]
        process = Process()
        process?.executableURL = URL(fileURLWithPath: executable)
        process?.arguments = args
        process?.environment = ProcessInfo.processInfo.environment
        do {
            try process?.run()
            isModelLoaded = true
            modelName = model
            NotificationService.shared.send(title: "MACRON", body: "LLM local cargado: \(model)")
        } catch {
            print("[LocalLLM] Error: \(error)")
        }
    }
    
    func stopLocalServer() {
        process?.terminate()
        isModelLoaded = false
        modelName = "Ninguno"
    }
}
