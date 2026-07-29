import Foundation
import AppKit

public final class SmartHomeScenes: @unchecked Sendable {
    public static let shared = SmartHomeScenes()
    private init() {}
    
    public enum Scene: String, CaseIterable {
        case morning = "Modo Manana"
        case night = "Modo Noche"
        case cinema = "Modo Cine"
        case focus = "Modo Focus"
        case party = "Modo Fiesta"
        case away = "Modo Ausente"
    }
    
    public func activate(_ scene: Scene) -> String {
        switch scene {
        case .morning:
            runShortcut(name: "MACRON Morning")
            return "Buenos dias. Luces al 80%, cortinas abiertas, musica suave."
        case .night:
            runShortcut(name: "MACRON Night")
            return "Modo noche activado. Luces al 10%, cortinas cerradas, DND on."
        case .cinema:
            runShortcut(name: "MACRON Cinema")
            return "Modo cine. Luces apagadas, Apple TV activado, volumen optimo."
        case .focus:
            runShortcut(name: "MACRON Focus")
            FocusSessionsPro.shared.startSession(type: .deepWork)
            return "Modo focus. Luces neutras, distracciones bloqueadas, sesion de 90 min."
        case .party:
            runShortcut(name: "MACRON Party")
            return "Modo fiesta. Luces de colores, musica alta, ambiente activado."
        case .away:
            runShortcut(name: "MACRON Away")
            return "Modo ausente. Todo apagado, seguridad activada."
        }
    }
    
    public func activateByVoice(command: String) -> String {
        let lower = command.lowercased()
        for scene in Scene.allCases {
            if lower.contains(scene.rawValue.lowercased()) || lower.contains(scene.rawValue.lowercased().replacingOccurrences(of: "modo ", with: "")) {
                return activate(scene)
            }
        }
        return "Escena no reconocida. Escenas disponibles: " + Scene.allCases.map { $0.rawValue }.joined(separator: ", ")
    }
    
    private func runShortcut(name: String) {
        let task = Process()
        task.launchPath = "/usr/bin/shortcuts"
        task.arguments = ["run", name]
        try? task.run()
    }
}
