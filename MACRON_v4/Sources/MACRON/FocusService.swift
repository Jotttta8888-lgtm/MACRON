import Foundation
public actor FocusService {
    public static let shared = FocusService()
    private init() {}
    public func enableFocus() -> String { "🧘 Modo Focus activado. Notificaciones silenciadas." }
    public func disableFocus() -> String { "🧘 Modo Focus desactivado." }
}
