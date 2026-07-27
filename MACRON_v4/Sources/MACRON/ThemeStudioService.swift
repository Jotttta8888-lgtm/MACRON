import Foundation
import SwiftUI

class ThemeStudioService: ObservableObject {
    static let shared = ThemeStudioService()
    @Published var currentTheme = "Default"
    @Published var customThemes: [CustomTheme] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/themes.json"
    
    struct CustomTheme: Identifiable, Codable {
        var id = UUID()
        let name: String
        let primaryColor: String
        let secondaryColor: String
        let backgroundColor: String
        let accentColor: String
        let fontName: String
    }
    
    func createTheme(name: String, primary: String, secondary: String, background: String, accent: String, font: String = "SF Pro") {
        let theme = CustomTheme(name: name, primaryColor: primary, secondaryColor: secondary, backgroundColor: background, accentColor: accent, fontName: font)
        customThemes.append(theme)
        save()
    }
    
    func applyTheme(_ name: String) {
        if customThemes.contains(where: { $0.name == name }) || name == "Default" {
            currentTheme = name
            NotificationService.shared.send(title: "MACRON Theme", body: "Tema aplicado: " + name)
        }
    }
    
    func exportTheme(_ name: String) -> String? {
        guard let theme = customThemes.first(where: { $0.name == name }) else { return nil }
        let data = try? JSONEncoder().encode(theme)
        return data?.base64EncodedString()
    }
    
    func importTheme(base64: String) -> Bool {
        guard let data = Data(base64Encoded: base64),
              let theme = try? JSONDecoder().decode(CustomTheme.self, from: data) else { return false }
        customThemes.append(theme)
        save()
        return true
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(customThemes)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([CustomTheme].self, from: data) else { return }
        customThemes = decoded
    }
}
