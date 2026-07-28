import Foundation
struct StatusResponse: Codable {
    let status: String?
    let version: String?
    let healthy: Bool?
    let modulesActive: Int?
    let modulesTotal: Int?
    let uptimeFormatted: String?
    let hardware: HardwareInfo?
    let active: [String]?
    let inactive: [String]?
}
struct HardwareInfo: Codable {
    let appleSilicon: Bool?
    let mlx: Bool?
    let mps: Bool?
    let ramGb: Double?
    let model: String?
}
struct ChatResponse: Codable {
    let text: String?
    let error: String?
    let model: String?
    let tokens: Int?
}
struct CalendarResponse: Codable {
    let events: [CalendarEvent]?
    let message: String?
    let error: String?
}
struct CalendarEvent: Codable, Identifiable {
    let id: String?
    let title: String?
    let startDate: String?
    let endDate: String?
    let location: String?
    let notes: String?
    var displayDate: String { startDate ?? "Sin fecha" }
}
struct NotesResponse: Codable {
    let notes: [Note]?
    let message: String?
    let error: String?
}
struct Note: Codable, Identifiable, Hashable {
    let id: String?
    let title: String?
    let content: String?
    let tags: String?
    let createdAt: String?
}
struct RemindersResponse: Codable {
    let reminders: [Reminder]?
    let message: String?
    let error: String?
}
struct Reminder: Codable, Identifiable {
    let id: String?
    let title: String?
    let dueDate: String?
    let priority: String?
    let completed: Bool?
}
struct FinderResponse: Codable {
    let results: [FinderItem]?
    let message: String?
    let error: String?
}
struct FinderItem: Codable, Identifiable {
    var id = UUID()
    let name: String?
    let path: String?
    let type: String?
    let size: Int?
    let icon: String?
    var formattedSize: String {
        guard let size = size else { return "--" }
        let kb = Double(size) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024
        return String(format: "%.1f GB", gb)
    }
}
struct SafariResponse: Codable {
    let bookmarks: [Bookmark]?
    let history: [HistoryItem]?
    let message: String?
    let error: String?
}
struct Bookmark: Codable, Identifiable {
    var id = UUID()
    let title: String?
    let url: String?
    let folder: String?
}
struct HistoryItem: Codable, Identifiable {
    var id = UUID()
    let title: String?
    let url: String?
    let visitCount: Int?
    let lastVisit: String?
}
struct MailResponse: Codable {
    let total: Int?
    let unread: Int?
    let recent: [MailMessage]?
    let message: String?
    let error: String?
}
struct MailMessage: Codable, Identifiable {
    var id = UUID()
    let subject: String?
    let sender: String?
    let preview: String?
    let date: String?
    let read: Bool?
}
struct FocusResponse: Codable {
    let active: Bool?
    let mode: String?
    let message: String?
    let error: String?
}
struct AnalyticsResponse: Codable {
    let stats: AnalyticsStats?
    let message: String?
    let error: String?
}
struct AnalyticsStats: Codable {
    let totalInteractions: Int?
    let totalTokens: Int?
    let avgResponseTime: Double?
    let topModules: [String]?
    let dailyUsage: [DailyUsage]?
}
struct DailyUsage: Codable, Identifiable {
    var id = UUID()
    let date: String?
    let count: Int?
}
struct ResearchResponse: Codable {
    let results: [ResearchResult]?
    let summary: String?
    let message: String?
    let error: String?
}
struct ResearchResult: Codable, Identifiable {
    var id = UUID()
    let title: String?
    let url: String?
    let snippet: String?
}

struct VoiceActionResponse: Codable {
    let action: String?
    let params: [String: String]?
    let response: String?
    let result: [String: String]?
    let original_text: String?
    let method: String?
    
    // Campos de error del backend
    let error: String?
    let text: String?
}
