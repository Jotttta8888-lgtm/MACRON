import Foundation
import CoreImage
import AppKit

class QRCodeGeneratorService {
    static let shared = QRCodeGeneratorService()
    
    func generateQR(text: String, size: CGFloat = 256) -> NSImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(text.data(using: .utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaleX = size / output.extent.size.width
        let scaleY = size / output.extent.size.height
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        let rep = NSCIImageRep(ciImage: transformed)
        let nsImage = NSImage(size: NSSize(width: size, height: size))
        nsImage.addRepresentation(rep)
        return nsImage
    }
    
    func generateWiFiQR(ssid: String, password: String, security: String = "WPA") -> NSImage? {
        let text = "WIFI:S:" + ssid + ";T:" + security + ";P:" + password + ";;"
        return generateQR(text: text)
    }
    
    func generateContactQR(name: String, phone: String, email: String) -> NSImage? {
        let text = "BEGIN:VCARD\\nVERSION:3.0\\nFN:" + name + "\\nTEL:" + phone + "\\nEMAIL:" + email + "\\nEND:VCARD"
        return generateQR(text: text)
    }
    
    func generateURLQR(_ url: String) -> NSImage? {
        return generateQR(text: url)
    }
    
    func saveQR(_ image: NSImage, filename: String) -> String? {
        let path = NSHomeDirectory() + "/Documents/MACRON/" + filename + ".png"
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return nil }
        try? png.write(to: URL(fileURLWithPath: path))
        return path
    }
}
