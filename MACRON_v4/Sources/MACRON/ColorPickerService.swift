import Foundation
import AppKit

public class ColorPickerService {
    func pickColorAt(x: Int, y: Int) -> String {
        guard let cgImage = CGDisplayCreateImage(CGMainDisplayID()) else {
            return "Error capturando pixel"
        }
        let rect = CGRect(x: x, y: Int(NSScreen.main?.frame.height ?? 1080) - y, width: 1, height: 1)
        guard let cropped = cgImage.cropping(to: rect) else {
            return "Error recortando pixel"
        }
        let pixel = cropped.pixelAt(x: 0, y: 0)
        guard let color = pixel else { return "Error leyendo color" }
        let hex = String(format: "#%02X%02X%02X", Int(color.redComponent * 255), Int(color.greenComponent * 255), Int(color.blueComponent * 255))
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hex, forType: .string)
        return hex
    }
}

extension CGImage {
    func pixelAt(x: Int, y: Int) -> NSColor? {
        guard let dataProvider = dataProvider, let data = dataProvider.data else { return nil }
        let pointer = CFDataGetBytePtr(data)
        _ = bytesPerRow
        let pixelInfo = ((width * y) + x) * 4
        let r = CGFloat(pointer![pixelInfo]) / 255.0
        let g = CGFloat(pointer![pixelInfo + 1]) / 255.0
        let b = CGFloat(pointer![pixelInfo + 2]) / 255.0
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
