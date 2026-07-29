import Foundation
import AppKit

public final class AIImageGenerator: @unchecked Sendable {
    public static let shared = AIImageGenerator()
    private init() {}
    
    public enum Model: String, CaseIterable {
        case stableDiffusion = "Stable Diffusion"
        case dalleLocal = "DALL-E Local"
        case placeholder = "Placeholder"
    }
    
    public var currentModel: Model = .placeholder
    
    public func generate(prompt: String, width: Int = 512, height: Int = 512) async -> String {
        switch currentModel {
        case .stableDiffusion:
            return await generateStableDiffusion(prompt: prompt, width: width, height: height)
        case .dalleLocal:
            return await generateDALLE(prompt: prompt)
        case .placeholder:
            return generatePlaceholder(prompt: prompt, width: width, height: height)
        }
    }
    
    public func createWallpaper(prompt: String) async -> String {
        let result = await generate(prompt: prompt, width: 1920, height: 1080)
        return result
    }
    
    private func generateStableDiffusion(prompt: String, width: Int, height: Int) async -> String {
        let script = "cd ~/stable-diffusion && python scripts/txt2img.py --prompt \"\(prompt)\" --W \(width) --H \(height) --outdir ~/Documents/MACRON/Images"
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", script]
        try? task.run()
        task.waitUntilExit()
        return "Imagen generada con Stable Diffusion. Revisa ~/Documents/MACRON/Images"
    }
    
    private func generateDALLE(prompt: String) async -> String {
        return "DALL-E Local requiere modelo descargado. Usa placeholder por ahora."
    }
    
    private func generatePlaceholder(prompt: String, width: Int, height: Int) -> String {
        let img = NSImage(size: NSSize(width: width, height: height))
        img.lockFocus()
        NSColor.darkGray.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24),
            .foregroundColor: NSColor.white
        ]
        let text = "MACRON AI\n" + prompt.prefix(30)
        text.draw(at: NSPoint(x: 20, y: height/2), withAttributes: attrs)
        img.unlockFocus()
        
        let path = NSHomeDirectory() + "/Documents/MACRON/wallpaper_" + String(Int(Date().timeIntervalSince1970)) + ".png"
        guard let tiff = img.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else {
            return "Error generando imagen placeholder"
        }
        try? data.write(to: URL(fileURLWithPath: path))
        return "Placeholder creado: " + path
    }
}
