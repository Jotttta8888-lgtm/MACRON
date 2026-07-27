import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true

    func toggle() {
        isDarkMode.toggle()
    }
}
