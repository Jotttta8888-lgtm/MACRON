import Foundation

// Extensiones de notificacion para compatibilidad entre modulos
extension NSNotification.Name {
    static let showSettings = NSNotification.Name("macron_showSettings")
    static let showChat = NSNotification.Name("macron_showChat")
    static let showCalendar = NSNotification.Name("macron_showCalendar")
    static let showVoiceAction = NSNotification.Name("macron_showVoiceAction")
    static let wakeWordDetected = NSNotification.Name("macron_wakeWordDetected")
    static let quickActionReceived = NSNotification.Name("macron_quickActionReceived")
}
