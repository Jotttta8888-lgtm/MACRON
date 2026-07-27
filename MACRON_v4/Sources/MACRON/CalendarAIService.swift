import Foundation
import EventKit

class CalendarAIService {
    static let shared = CalendarAIService()
    private let store = EKEventStore()
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        store.requestFullAccessToEvents { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }
    
    func getTodayEvents() -> [String] {
        let start = Calendar.current.startOfDay(for: Date())
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate)
        return events.map { "\($0.title ?? "Sin titulo") - \($0.startDate.formatted(date: .omitted, time: .shortened))" }
    }
    
    func suggestPreparation() -> String {
        let events = getTodayEvents()
        guard let first = events.first else { return "Sin eventos hoy" }
        return "Proximo: " + first + ". Preparate con anticipacion."
    }
}
