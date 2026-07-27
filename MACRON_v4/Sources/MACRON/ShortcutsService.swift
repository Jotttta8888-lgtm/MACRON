import AppIntents

struct OpenMACRONIntent: AppIntent {
    static var title: LocalizedStringResource = "Abrir MACRON"
    static var description = IntentDescription("Abre la ventana principal de MACRON")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct SendCommandIntent: AppIntent {
    static var title: LocalizedStringResource = "Enviar comando a MACRON"
    static var description = IntentDescription("Envia un comando de texto al agente MACRON")
    
    @Parameter(title: "Comando", requestValueDialog: "Que quieres que haga MACRON?")
    var command: String
    
    func perform() async throws -> some IntentResult {
        let url = URL(string: "http://localhost:5001/api/voice-action")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["text": command]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        let success = (response as? HTTPURLResponse)?.statusCode == 200
        return .result(dialog: success ? "Comando enviado: \(command)" : "Error al enviar comando")
    }
}

struct MACRONShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: OpenMACRONIntent(),
                phrases: ["Abre MACRON", "Inicia MACRON", "Abrir mi agente de IA"],
                shortTitle: "Abrir MACRON",
                systemImageName: "brain.head.profile"
            ),
            AppShortcut(
                intent: SendCommandIntent(),
                phrases: ["Enviar comando a MACRON", "Pidele algo a MACRON"],
                shortTitle: "Comando a MACRON",
                systemImageName: "command"
            )
        ]
    }
}
