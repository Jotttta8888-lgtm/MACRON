import Foundation
import EventKit

class SmartRemindersService {
    static let shared = SmartRemindersService()
    private let eventStore = EKEventStore()
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .reminder) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }
    
    func createReminder(title: String, notes: String = "", dueDate: Date? = nil) -> Bool {
        guard EKEventStore.authorizationStatus(for: .reminder) == .authorized else { return false }
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        if let due = dueDate {
            let alarm = EKAlarm(absoluteDate: due)
            reminder.addAlarm(alarm)
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        }
        do {
            try eventStore.save(reminder, commit: true)
            NotificationService.shared.send(title: "MACRON", body: "Recordatorio creado: " + title)
            return true
        } catch {
            print("Error creando recordatorio: " + String(describing: error))
            return false
        }
    }
    
    func createReminderFromContext(_ text: String) -> Bool {
        var title = text
        var dueDate: Date? = nil
        let patterns = [
            ("en (\\d+) minutos", 60),
            ("en (\\d+) horas", 3600),
            ("en (\\d+) dias", 86400),
            ("mañana", 86400)
        ]
        for (pattern, seconds) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                if let range = Range(match.range(at: 1), in: text), let val = Int(text[range]) {
                    dueDate = Date().addingTimeInterval(TimeInterval(val * seconds))
                } else if pattern == "mañana" {
                    dueDate = Date().addingTimeInterval(TimeInterval(seconds))
                }
                title = text.replacingOccurrences(of: (text as NSString).substring(with: match.range), with: "").trimmingCharacters(in: .whitespaces)
                break
            }
        }
        return createReminder(title: title, dueDate: dueDate)
    }
}
