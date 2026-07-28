import Foundation
import AppKit
import UserNotifications

public final class ProactiveAI: @unchecked Sendable {
    public static let shared = ProactiveAI()
    public enum Insight: Sendable { case overwork(duration: TimeInterval), procrastination(app: String, duration: TimeInterval), breakSuggestion, focusOpportunity, hydrationReminder, meetingSoon(title: String, minutes: Int), custom(title: String, body: String) }
    private var appUsage: [String: TimeInterval] = [:]
    private var currentAppStart: Date?, currentApp: String = "", lastBreak: Date = Date(), insightsLog: [String] = []
    private let queue = DispatchQueue(label: "macron.proactive", qos: .utility)
    private var timer: Timer?, isEnabled = true
    private let overworkThreshold: TimeInterval = 7200
    private let procrastinationApps = ["YouTube","TikTok","Instagram","Twitter","Reddit","Netflix"]
    private let procrastinationThreshold: TimeInterval = 1800
    private init() { requestNotificationAuth() }
    public func startMonitoring(interval: TimeInterval = 30.0) {
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in self?.queue.async { self?.tick() } }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }
    public func stopMonitoring() { timer?.invalidate(); timer = nil }
    public func setEnabled(_ enabled: Bool) { isEnabled = enabled; if !enabled { stopMonitoring() } }
    @objc private func appChanged(_ n: Notification) { queue.async { [weak self] in self?.recordAppSwitch() } }
    private func tick() { guard isEnabled else { return }; recordAppSwitch(); checkInsights() }
    private func recordAppSwitch() {
        let now = Date()
        if let s = currentAppStart, !currentApp.isEmpty { appUsage[currentApp, default: 0] += now.timeIntervalSince(s) }
        currentApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
        currentAppStart = now
    }
    private func checkInsights() {
        let now = Date()
        let wt = now.timeIntervalSince(lastBreak)
        if wt > overworkThreshold { emit(.overwork(duration: wt)); lastBreak = now; return }
        if procrastinationApps.contains(currentApp), let t = appUsage[currentApp], t > procrastinationThreshold { emit(.procrastination(app: currentApp, duration: t)); appUsage[currentApp] = 0; return }
        if wt > 5400 { emit(.breakSuggestion); lastBreak = now; return }
        let lh = UserDefaults.standard.object(forKey: "macron_last_hydration") as? Date ?? Date.distantPast
        if now.timeIntervalSince(lh) > 7200 { emit(.hydrationReminder); UserDefaults.standard.set(now, forKey: "macron_last_hydration"); return }
        let h = Calendar.current.component(.hour, from: now)
        if h >= 6 && h <= 9, !procrastinationApps.contains(currentApp) {
            let lf = UserDefaults.standard.object(forKey: "macron_last_focus_tip") as? Date ?? Date.distantPast
            if now.timeIntervalSince(lf) > 14400 { emit(.focusOpportunity); UserDefaults.standard.set(now, forKey: "macron_last_focus_tip"); return }
        }
    }
    private func emit(_ i: Insight) {
        let (t, b): (String, String)
        switch i {
        case .overwork(let d): let m = Int(d/60); t = "⚠️ Llevas \(m) min sin descansar"; b = "Tu cerebro necesita un break de 5 min. Levantate, estira, respira."
        case .procrastination(let a, let d): let m = Int(d/60); t = "🦥 ¿Seguro que quieres seguir en \(a)?"; b = "Llevas \(m) min aqui. ¿No tenias algo mas importante?"
        case .breakSuggestion: t = "☕ Momento de un break"; b = "Tu sesion de focus lleva 90 min. Un descanso de 10 min mejorara tu rendimiento."
        case .focusOpportunity: t = "🎯 Ventana de focus detectada"; b = "Es temprano y no hay distracciones. ¿Quieres activar una sesion de focus?"
        case .hydrationReminder: t = "💧 Hora de hidratarte"; b = "Llevas 2h sin beber agua. Tu cerebro funciona mejor hidratado."
        case .meetingSoon(let mt, let mn): t = "📅 Reunion en \(mn) min"; b = "\(mt) — preparate."
        case .custom(let ct, let cb): t = ct; b = cb
        }
        let c = UNMutableNotificationContent(); c.title = t; c.body = b; c.sound = .default; c.categoryIdentifier = "macron_proactive"
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
        insightsLog.append("[\(ISO8601DateFormatter().string(from: Date()))] \(t): \(b)")
        if insightsLog.count > 100 { insightsLog.removeFirst() }
    }
    private func requestNotificationAuth() { UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]) { _,_ in } }
    public func log() -> [String] { insightsLog }
    public func resetLog() { insightsLog.removeAll() }
}
