import Foundation
public actor PluginService {
    public static let shared = PluginService()
    private init() {}
    public func listPlugins() -> String { "🔌 Plugins disponibles:\n  • meeting-recorder\n  • homekit-bridge\n  • file-organizer\n  • translator\n  • smart-search\n\nEscribe 'Instalar plugin <nombre>' para activar." }
    public func installPlugin(name: String) -> String { "✅ Plugin '\(name)' activado. Reinicia MACRON para aplicar cambios." }
}
