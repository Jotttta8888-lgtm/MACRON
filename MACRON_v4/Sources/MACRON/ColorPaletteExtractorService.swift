import Foundation
import AppKit

class ColorPaletteExtractorService {
    static let shared = ColorPaletteExtractorService()
    
    func extractPalette(from imagePath: String, colorCount: Int = 5) -> [String] {
        guard let image = NSImage(contentsOfFile: imagePath),
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let cgImage = bitmap.cgImage else { return [] }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return [] }
        
        var colors: [String: Int] = [:]
        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let offset = (y * width + x) * 4
                let r = pixelBuffer[offset]
                let g = pixelBuffer[offset + 1]
                let b = pixelBuffer[offset + 2]
                let hex = String(format: "#%02X%02X%02X", r, g, b)
                colors[hex, default: 0] += 1
            }
        }
        
        return colors.sorted { $0.value > $1.value }.prefix(colorCount).map { $0.key }
    }
}
