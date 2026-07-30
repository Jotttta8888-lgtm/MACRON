import Foundation
import EventKit

public actor CalendarService {
    public static let shared = CalendarService()
    private let store = EKEventStore()
    private init() {}
    
    public func requestAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .fullAccess {
            return true
        }
        if #available(macOS 14.0, *) {
            return (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            return (try? await store.requestAccess(to: .event)) ?? false
        }
    }
    
    public func createEvent(title: String, dateComponents: DateComponents) async -> String {
        guard await requestAccess() else {
            return "❌ Necesito permiso para acceder al Calendario. Ve a Ajustes del Sistema → Privacidad y Seguridad → Calendarios."
        }
        
        guard let defaultCalendar = store.defaultCalendarForNewEvents else {
            return "❌ No se encontró un calendario por defecto."
        }
        
        let event = EKEvent(eventStore: store)
        event.title = title
        event.calendar = defaultCalendar
        
        let currentCalendar = Calendar.current
        var finalComponents = dateComponents
        
        if finalComponents.year == nil {
            let now = currentCalendar.dateComponents([.year, .month, .day], from: Date())
            finalComponents.year = now.year
            finalComponents.month = now.month
            finalComponents.day = now.day
        }
        
        guard let startDate = currentCalendar.date(from: finalComponents) else {
            return "❌ No pude entender la fecha. Prueba: 'Reúnete con María mañana a las 15:00'"
        }
        
        event.startDate = startDate
        event.endDate = currentCalendar.date(byAdding: .hour, value: 1, to: startDate)
        event.alarms = [EKAlarm(relativeOffset: -600)]
        
        do {
            try store.save(event, span: .thisEvent)
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "es_ES")
            return "✅ Evento creado: '" + title + "' el " + formatter.string(from: startDate) + "."
        } catch {
            return "❌ Error al guardar el evento: " + error.localizedDescription
        }
    }
    
    nonisolated public func parseNaturalDate(text: String) -> DateComponents {
        let lower = text.lowercased()
        let currentCalendar = Calendar.current
        var components = DateComponents()
        let now = Date()
        
        if lower.contains("mañana") || lower.contains("manana") {
            let tomorrow = currentCalendar.date(byAdding: .day, value: 1, to: now)!
            let d = currentCalendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.year = d.year; components.month = d.month; components.day = d.day
        } else if lower.contains("pasado mañana") || lower.contains("pasado manana") {
            let dayAfter = currentCalendar.date(byAdding: .day, value: 2, to: now)!
            let d = currentCalendar.dateComponents([.year, .month, .day], from: dayAfter)
            components.year = d.year; components.month = d.month; components.day = d.day
        } else if lower.contains("próxima semana") || lower.contains("proxima semana") {
            let nextWeek = currentCalendar.date(byAdding: .weekOfYear, value: 1, to: now)!
            let d = currentCalendar.dateComponents([.year, .month, .day], from: nextWeek)
            components.year = d.year; components.month = d.month; components.day = d.day
        } else if lower.contains("hoy") {
            let d = currentCalendar.dateComponents([.year, .month, .day], from: now)
            components.year = d.year; components.month = d.month; components.day = d.day
        }
        
        let patterns = [
            "a las (\\d{1,2}):(\\d{2})",
            "a las (\\d{1,2})",
            "(\\d{1,2}):(\\d{2})",
            "(\\d{1,2}) (am|pm)",
            "(\\d{1,2})(am|pm)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                
                let hourRange = match.range(at: 1)
                if let hourRange = Range(hourRange, in: text),
                   let hour = Int(text[hourRange]) {
                    components.hour = hour
                }
                
                if match.numberOfRanges > 2 {
                    let minRange = match.range(at: 2)
                    if let minRange = Range(minRange, in: text),
                       let minute = Int(text[minRange]) {
                        components.minute = minute
                    } else {
                        components.minute = 0
                    }
                } else {
                    components.minute = 0
                }
                
                if lower.contains("pm") && components.hour != nil && components.hour! < 12 {
                    components.hour! += 12
                }
                break
            }
        }
        
        return components
    }
    
    nonisolated public func extractTitle(from text: String) -> String {
        var title = text
        let timeWords = ["reunete", "reúnete", "reunete con", "reunión", "reunion", "reunion con", "agenda", "agenda con",
                         "crea evento", "programa", "programa con", "mañana", "manana", "hoy",
                         "pasado mañana", "pasado manana", "próxima semana", "proxima semana",
                         "a las", "pm", "am", "con"]
        for word in timeWords {
            title = title.replacingOccurrences(of: word, with: "", options: .caseInsensitive)
        }
        
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty { title = "Reunión MACRON" }
        return title
    }
}
