import Foundation
import AppKit

public final class WindowManagerAI: @unchecked Sendable {
    public static let shared = WindowManagerAI()
    private init() {}
    
    public func focusMode() -> String {
        let ctx = VoiceContextEngine.shared.currentContext
        let apps = getRunningApps()
        guard let screen = NSScreen.main else { return "❌ No se detecto pantalla." }
        let frame = screen.visibleFrame
        let halfWidth = frame.width / 2
        let leftFrame = NSRect(x: frame.minX, y: frame.minY, width: halfWidth, height: frame.height)
        let rightFrame = NSRect(x: frame.minX + halfWidth, y: frame.minY, width: halfWidth, height: frame.height)
        if let mainApp = apps.first(where: { $0.name.lowercased() == ctx.appName.lowercased() }) { positionWindow(pid: mainApp.pid, frame: leftFrame) }
        if let secondary = apps.first(where: { ["safari", "preview", "notes", "mail"].contains($0.name.lowercased()) }) { positionWindow(pid: secondary.pid, frame: rightFrame) }
        for app in apps { if ["slack", "whatsapp", "telegram", "messages"].contains(app.name.lowercased()) { minimizeApp(pid: app.pid) } }
        return "✅ Modo Focus activado. \(ctx.appName) a la izquierda, referencias a la derecha. Distracciones minimizadas."
    }
    
    public func gridMode() -> String {
        guard let screen = NSScreen.main else { return "❌ No se detecto pantalla." }
        let frame = screen.visibleFrame
        let w = frame.width / 2, h = frame.height / 2
        let positions = [
            NSRect(x: frame.minX, y: frame.minY + h, width: w, height: h),
            NSRect(x: frame.minX + w, y: frame.minY + h, width: w, height: h),
            NSRect(x: frame.minX, y: frame.minY, width: w, height: h),
            NSRect(x: frame.minX + w, y: frame.minY, width: w, height: h)
        ]
        let apps = getRunningApps().prefix(4)
        for (index, app) in apps.enumerated() { positionWindow(pid: app.pid, frame: positions[index]) }
        return "✅ Grid 2x2 aplicado a \(apps.count) ventanas."
    }
    
    public func maximizeActive() -> String {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return "❌ No hay app activa." }
        guard let screen = NSScreen.main else { return "❌ No se detecto pantalla." }
        positionWindow(pid: frontApp.processIdentifier, frame: screen.visibleFrame)
        return "✅ Ventana maximizada."
    }
    
    public func restoreAll() -> String {
        let apps = getRunningApps()
        var x: CGFloat = 100, y: CGFloat = 100
        for app in apps { positionWindow(pid: app.pid, frame: NSRect(x: x, y: y, width: 800, height: 600)); x += 30; y += 30 }
        return "✅ Ventanas restauradas a posicion en cascada."
    }
    
    private struct AppInfo { let name: String; let pid: pid_t }
    private func getRunningApps() -> [AppInfo] {
        return NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }.map { AppInfo(name: $0.localizedName ?? "Unknown", pid: $0.processIdentifier) }
    }
    
    private func positionWindow(pid: pid_t, frame: NSRect) {
        let appRef = AXUIElementCreateApplication(pid)
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value) == .success, let windows = value as? [AXUIElement] else { return }
        for window in windows {
            var position = CGPoint(x: frame.minX, y: frame.minY)
            var size = CGSize(width: frame.width, height: frame.height)
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &position)!)
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &size)!)
        }
    }
    
    private func minimizeApp(pid: pid_t) {
        let appRef = AXUIElementCreateApplication(pid)
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value) == .success, let windows = value as? [AXUIElement] else { return }
        for window in windows { AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, true as CFTypeRef) }
    }
}
