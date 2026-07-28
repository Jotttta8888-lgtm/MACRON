import Foundation
import AppKit
import EventKit

public final class SmartScheduler: @unchecked Sendable {
    public static let shared = SmartScheduler()
    private let eventStore = EKEventStore()
    private init() {}
    
    public func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { granted, _ in DispatchQueue.main.async { completion(granted) } }
        } else {
            eventStore.requestAccess(to: .event) { granted, _ in DispatchQueue.main.async { completion(granted) } }
        }
    }
    
    public func scheduleMeeting(title: String, attendees: [String], date: Date, duration: TimeInterval = 3600) -> String {
        let authStatus: EKAuthorizationStatus
        if #available(macOS 14.0, *) {
            authStatus = EKEventStore.authorizationStatus(for: .event)
        } else {
            authStatus = EKEventStore.authorizationStatus(for: .event)
        }
        if #available(macOS 14.0, *) {
            guard authStatus == .fullAccess else {
                return "❌ Sin permiso para Calendar. Ve a Preferencias del Sistema > Seguridad > Calendarios."
            }
        } else {
            guard authStatus == .authorized else {
                return "❌ Sin permiso para Calendar. Ve a Preferencias del Sistema > Seguridad > Calendarios."
            }
        }
        guard let calendar = eventStore.defaultCalendarForNewEvents else { return "❌ No hay calendario predeterminado." }
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = date
        event.endDate = date.addingTimeInterval(duration)
        event.calendar = calendar
        event.location = "Reunion MACRON"
        event.notes = "Creado por MACRON Agent"
        if !attendees.isEmpty { event.notes = "\(event.notes ?? "")\n\nAsistentes: \(attendees.joined(separator: ", "))" }
        do {
            try eventStore.save(event, span: .thisEvent)
            let meetLink = "https://meet.google.com/\(randomString(length: 3))-\(randomString(length: 4))-\(randomString(length: 3))"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(meetLink, forType: .string)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium; formatter.timeStyle = .short; formatter.locale = Locale(identifier: "es_ES")
            return "✅ Reunion '\(title)' agendada para \(formatter.string(from: date)).\n🔗 Enlace Meet copiado: \(meetLink)"
        } catch { return "❌ Error guardando evento: \(error.localizedDescription)" }
    }
    
    public func findFreeSlots(duration: TimeInterval = 3600) -> [Date] {
        let authStatus: EKAuthorizationStatus
        if #available(macOS 14.0, *) {
            authStatus = EKEventStore.authorizationStatus(for: .event)
        } else {
            authStatus = EKEventStore.authorizationStatus(for: .event)
        }
        if #available(macOS 14.0, *) {
            guard authStatus == .fullAccess else { return [] }
        } else {
            guard authStatus == .authorized else { return [] }
        }
        let now = Date()
        let tomorrow = now.addingTimeInterval(86400)
        let predicate = eventStore.predicateForEvents(withStart: now, end: tomorrow, calendars: nil)
        let events = eventStore.events(matching: predicate)
        var slots: [Date] = []
        var cursor = now
        let hour = Calendar.current.component(.hour, from: cursor)
        if hour < 9 { cursor = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: cursor) ?? cursor }
        while cursor < tomorrow {
            let slotEnd = cursor.addingTimeInterval(duration)
            let hasConflict = events.contains { cursor < $0.endDate && slotEnd > $0.startDate }
            if !hasConflict { slots.append(cursor) }
            cursor = cursor.addingTimeInterval(1800)
            if Calendar.current.component(.hour, from: cursor) >= 20 { break }
        }
        return Array(slots.prefix(5))
    }
    
    public func parseAndSchedule(_ command: String) -> String {
        let lower = command.lowercased()
        var title = "Reunion"
        if let range = lower.range(of: "reunete con ") {
            let after = String(lower[range.upperBound...])
            let components = after.components(separatedBy: .whitespacesAndNewlines)
            if let first = components.first, !first.isEmpty { title = "Reunion con \(first.capitalized)" }
        }
        var targetDate = Date()
        let cal = Calendar.current
        if lower.contains("manana") { targetDate = cal.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate }
        if lower.contains("hoy") { targetDate = Date() }
        let digits = lower.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
        if let hourStr = digits.first, let hour = Int(hourStr) {
            targetDate = cal.date(bySettingHour: hour, minute: 0, second: 0, of: targetDate) ?? targetDate
        } else {
            targetDate = cal.date(bySettingHour: 10, minute: 0, second: 0, of: targetDate) ?? targetDate
        }
        return scheduleMeeting(title: title, attendees: [], date: targetDate)
    }
    
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}
