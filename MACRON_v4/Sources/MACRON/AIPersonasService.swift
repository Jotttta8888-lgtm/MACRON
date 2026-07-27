import Foundation

class AIPersonasService: ObservableObject {
    static let shared = AIPersonasService()
    @Published var currentPersona = "Default"
    
    let personas = [
        "Default": "Soy MACRON, tu asistente personal.",
        "Developer": "Soy MACRON en modo Developer. Uso terminologia tecnica y doy soluciones de codigo.",
        "Chef": "Soy MACRON Chef. Sugiero recetas, tecnicas de cocina y planificacion de comidas.",
        "Fitness": "Soy MACRON Fitness. Te motivo, sugiero rutinas y tracking de progreso.",
        "Writer": "Soy MACRON Writer. Ayudo con redaccion, estilo y correccion creativa."
    ]
    
    func setPersona(_ name: String) {
        if personas.keys.contains(name) {
            currentPersona = name
            NotificationService.shared.send(title: "MACRON", body: "Persona activa: " + name)
        }
    }
    
    func getResponseStyle() -> String {
        return personas[currentPersona] ?? personas["Default"]!
    }
}
