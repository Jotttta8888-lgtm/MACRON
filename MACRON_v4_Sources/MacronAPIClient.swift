import SwiftUI
import Combine
@MainActor
class MacronAPIClient: ObservableObject {
    static let shared = MacronAPIClient()
    private let baseURL = "http://localhost:5002"
    private var session: URLSession
    private var healthCheckTimer: Timer?
    @Published var isOnline = false
    @Published var lastError: String?
    @Published var status: StatusResponse?
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        startHealthCheck()
    }
    func startHealthCheck() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task { @MainActor in _ = await self.checkHealth() }
        }
        Task { @MainActor in _ = await self.checkHealth() }
    }
    private func request<T: Decodable>(path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw MacronError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw MacronError.invalidResponse }
        if httpResponse.statusCode >= 400 { throw MacronError.httpError(code: httpResponse.statusCode) }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
    func checkHealth() async -> Bool {
        do {
            let status: StatusResponse = try await request(path: "/api/status")
            self.status = status; self.isOnline = status.healthy ?? false; self.lastError = nil
            return status.healthy ?? false
        } catch { self.isOnline = false; self.lastError = error.localizedDescription; return false }
    }
    func sendChat(message: String) async throws -> ChatResponse {
        try await request(path: "/api/chat", method: "POST", body: ["message": message, "session_id": "swiftui"])
    }
    func getTodayEvents() async throws -> CalendarResponse { try await request(path: "/api/calendar/today") }
    func createEvent(title: String, startDate: String, endDate: String? = nil, notes: String = "") async throws -> CalendarResponse {
        var body: [String: Any] = ["title": title, "start_date": startDate, "notes": notes]
        if let endDate = endDate { body["end_date"] = endDate }
        return try await request(path: "/api/calendar/event", method: "POST", body: body)
    }
    func getNotes() async throws -> NotesResponse { try await request(path: "/api/notes") }
    func createNote(title: String, content: String, tags: [String] = []) async throws -> NotesResponse {
        try await request(path: "/api/notes", method: "POST", body: ["title": title, "content": content, "tags": tags])
    }
    func getReminders() async throws -> RemindersResponse { try await request(path: "/api/reminders") }
    func createReminder(title: String, dueDate: String? = nil, priority: String = "normal") async throws -> RemindersResponse {
        var body: [String: Any] = ["title": title, "priority": priority]
        if let dueDate = dueDate { body["due_date"] = dueDate }
        return try await request(path: "/api/reminders", method: "POST", body: body)
    }
    func searchFiles(query: String, path: String = "~") async throws -> FinderResponse {
        try await request(path: "/api/finder/search", method: "POST", body: ["query": query, "path": path])
    }
    func getBookmarks() async throws -> SafariResponse { try await request(path: "/api/safari/bookmarks") }
    func getHistory(limit: Int = 50) async throws -> SafariResponse { try await request(path: "/api/safari/history?limit=\(limit)") }
    func getMailSummary() async throws -> MailResponse { try await request(path: "/api/mail/summary") }
    func getFocusStatus() async throws -> FocusResponse { try await request(path: "/api/focus/status") }
    func toggleFocus(mode: String) async throws -> FocusResponse { try await request(path: "/api/focus/toggle", method: "POST", body: ["mode": mode]) }
    func getAnalytics() async throws -> AnalyticsResponse { try await request(path: "/api/analytics") }
    func research(query: String, maxResults: Int = 5) async throws -> ResearchResponse {
        try await request(path: "/api/research", method: "POST", body: ["query": query, "max_results": maxResults])
    }
}
enum MacronError: Error, LocalizedError {
    case invalidURL, invalidResponse, endpointNotFound, httpError(code: Int), decodingError, offline
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL invalida"
        case .invalidResponse: return "Respuesta invalida del servidor"
        case .endpointNotFound: return "Endpoint no encontrado"
        case .httpError(let code): return "Error HTTP: \(code)"
        case .decodingError: return "Error decodificando respuesta"
        case .offline: return "MACRON offline - Verifica que el backend este corriendo"
        }
    }
}
