import Foundation
import AppKit

class ColorPickerService {
    static let shared = ColorPickerService()
    
    func pickColorFromScreen(x: Int, y: Int) -> String {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let rect = NSRect(x: x, y: Int(screen.frame.height) - y, width: 1, height: 1)
        guard let cgImage = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
            return "Error capturando pixel"
        }
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return "Error leyendo pixel" }
        let r = ptr[0]
        let g = ptr[1]
        let b = ptr[2]
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    func generatePalette(from hex: String) -> [String] {
        guard hex.count == 7, let rgb = Int(hex.dropFirst(), radix: 16) else { return [] }
        let r = (rgb >> 16) & 0xFF
        let g = (rgb >> 8) & 0xFF
        let b = rgb & 0xFF
        let complementary = String(format: "#%02X%02X%02X", 255 - r, 255 - g, 255 - b)
        let analogous1 = String(format: "#%02X%02X%02X", (r + 30) % 255, g, b)
        let analogous2 = String(format: "#%02X%02X%02X", (r + 60) % 255, g, b)
        return [hex, complementary, analogous1, analogous2]
    }
}
