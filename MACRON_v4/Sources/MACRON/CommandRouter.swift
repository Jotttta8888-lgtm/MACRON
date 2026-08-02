import Foundation

public protocol CommandHandler: Sendable {
    var keywords: [String] { get }
    func handle(text: String, brain: MACRONBrain) async -> String
}

public final class CommandRouter: @unchecked Sendable {
    public static let shared = CommandRouter()
    private var handlers: [CommandHandler] = []
    private var isSetup = false

    private init() {}

    public func setup() async {
        guard !isSetup else { return }
        isSetup = true
        register(WeatherHandler())
        register(CryptoHandler())
        register(TranslationHandler())
        register(CalendarHandler())
        register(MemoryHandler())
        register(StatsHandler())
    }

    public func register(_ handler: CommandHandler) {
        handlers.append(handler)
    }

    public func route(text: String, brain: MACRONBrain) async -> String? {
        let lower = text.lowercased()
        for handler in handlers {
            for keyword in handler.keywords {
                if lower.contains(keyword) {
                    return await handler.handle(text: text, brain: brain)
                }
            }
        }
        return nil
    }

    public func listHandlers() -> String {
        var lines: [String] = ["🧩 Handlers (\(handlers.count)):"]
        for handler in handlers {
            lines.append("  • \(type(of: handler)): \(handler.keywords.joined(separator: ", "))")
        }
        return lines.joined(separator: "\n")
    }
}

public struct WeatherHandler: CommandHandler {
    public let keywords = ["clima", "weather", "temperatura", "tiempo", "forecast"]
    public func handle(text: String, brain: MACRONBrain) async -> String {
        let cities = ["bogota", "medellin", "cali", "cartagena", "barranquilla", "miami", "madrid", "tokio", "londres", "paris", "new york", "berlin"]
        let lower = text.lowercased()
        var city = "Bogota"
        for c in cities { if lower.contains(c) { city = c.capitalized; break } }
        let res = brain.orchestrator.execute(toolName: "weather", arguments: ["city": city])
        if res.contains("❌") { return "❌ No pude obtener el clima de \(city)." }
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if let proactive = await AutonomousEngine.shared.evaluateProactivityOnly() {
                await MainActor.run { brain.onAIResponse?(proactive); brain.speak(proactive) }
            }
        }
        return res
    }
}

public struct CryptoHandler: CommandHandler {
    public let keywords = ["crypto", "bitcoin", "btc", "ethereum", "eth", "precio"]
    public func handle(text: String, brain: MACRONBrain) async -> String {
        let res = brain.orchestrator.execute(toolName: "crypto", arguments: ["symbol": "BTC"])
        if res.contains("❌") { return "❌ No pude obtener datos de crypto." }
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if let proactive = await AutonomousEngine.shared.evaluateProactivityOnly() {
                await MainActor.run { brain.onAIResponse?(proactive); brain.speak(proactive) }
            }
        }
        return res
    }
}

public struct TranslationHandler: CommandHandler {
    public let keywords = ["traduce", "translate", "traducir"]
    public func handle(text: String, brain: MACRONBrain) async -> String {
        let lower = text.lowercased()
        var toTranslate = text
        for prefix in ["traduce", "translate", "traducir"] {
            if lower.contains(prefix), let range = lower.range(of: prefix) {
                toTranslate = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        return brain.orchestrator.execute(toolName: "translate", arguments: ["text": toTranslate, "target_lang": "en"])
    }
}

public struct CalendarHandler: CommandHandler {
    public let keywords = ["calendario", "calendar", "reunion", "meeting", "agenda", "cita"]
    public func handle(text: String, brain: MACRONBrain) async -> String {
        return "📅 Calendario en desarrollo."
    }
}

public struct MemoryHandler: CommandHandler {
    public let keywords = ["memoria", "memory", "recuerdas", "recuerda", "olvida", "contexto"]
    public func handle(text: String, brain: MACRONBrain) async -> String {
        let lower = text.lowercased()
        if lower.contains("que recuerdas") || lower.contains("mi memoria") {
            let ctx = await MemoryService.shared.getContext()
            return ctx.isEmpty ? "🧠 No tengo nada en memoria aun." : "🧠 Recuerdo:\n\(ctx)"
        }
        if lower.contains("olvida") || lower.contains("borra memoria") {
            await MemoryService.shared.clear()
            return "🧠 Memoria borrada."
        }
        return "🧠 Comando de memoria no reconocido."
    }
}

public struct StatsHandler: CommandHandler {
    public let keywords = ["estadisticas", "stats", "mi uso", "dashboard"]
    public func handle(text: String, brain: MACRONBrain) async -> String {
        return await AutonomousEngine.shared.getStats()
    }
}
