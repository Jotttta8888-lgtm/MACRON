import Foundation

public final class LLMConnector: @unchecked Sendable {
    public static let shared = LLMConnector()
    
    public enum Provider: String, CaseIterable {
        case ollama = "Ollama"
        case llamaCPP = "llama.cpp"
        case custom = "Custom"
    }
    
    public var provider: Provider = .ollama
    public var baseURL: String = "http://localhost:11434"
    public var model: String = "llama3.2"
    public var timeout: TimeInterval = 60.0
    public var isAvailable: Bool = false
    
    private let session: URLSession
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }
    
    public func generate(prompt: String, systemPrompt: String? = nil) async -> String {
        let fullPrompt = systemPrompt != nil ? "[SYSTEM]\n" + systemPrompt! + "\n\n[USER]\n" + prompt : prompt
        switch provider {
        case .ollama: return await generateOllama(prompt: fullPrompt)
        case .llamaCPP: return await generateLlamaCPP(prompt: fullPrompt)
        case .custom: return await generateCustom(prompt: fullPrompt)
        }
    }
    
    private func generateOllama(prompt: String) async -> String {
        guard let url = URL(string: baseURL + "/api/generate") else { return "URL invalida" }
        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "options": ["temperature": 0.7]
        ]
        return await performRequest(url: url, body: body, responseKey: "response")
    }
    
    private func generateLlamaCPP(prompt: String) async -> String {
        guard let url = URL(string: baseURL + "/completion") else { return "URL invalida" }
        let body: [String: Any] = [
            "prompt": prompt,
            "temperature": 0.7,
            "n_predict": 512
        ]
        return await performRequest(url: url, body: body, responseKey: "content")
    }
    
    private func generateCustom(prompt: String) async -> String {
        guard let url = URL(string: baseURL) else { return "URL invalida" }
        let body: [String: Any] = ["prompt": prompt]
        return await performRequest(url: url, body: body, responseKey: "response")
    }
    
    private func performRequest(url: URL, body: [String: Any], responseKey: String) async -> String {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return "Error HTTP: " + String((response as? HTTPURLResponse)?.statusCode ?? 0)
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                if let text = String(data: data, encoding: .utf8) { return text }
                return "Respuesta no valida"
            }
            if let text = json[responseKey] as? String { return text }
            if let text = json["response"] as? String { return text }
            if let text = json["content"] as? String { return text }
            return "Respuesta recibida pero campo no encontrado"
        } catch {
            return "Error: " + error.localizedDescription + ". Asegurate de que " + provider.rawValue + " este corriendo en " + baseURL
        }
    }
    
    public func checkAvailability() async -> Bool {
        guard let url = URL(string: baseURL + "/api/tags") else { return false }
        do {
            let (_, response) = try await session.data(from: url)
            isAvailable = (response as? HTTPURLResponse)?.statusCode == 200
            return isAvailable
        } catch {
            isAvailable = false
            return false
        }
    }
    
    public func listModels() async -> [String] {
        guard provider == .ollama, let url = URL(string: baseURL + "/api/tags") else { return [] }
        do {
            let (data, _) = try await session.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["models"] as? [[String: Any]] else { return [] }
            return models.compactMap { $0["name"] as? String }
        } catch { return [] }
    }
}
