import Foundation

public final class SmartFileOrganizer: @unchecked Sendable {
    public static let shared = SmartFileOrganizer()
    private init() {}
    
    public enum OrganizeRule: String, CaseIterable {
        case byType = "Por tipo"
        case byDate = "Por fecha"
        case bySize = "Por tamano"
        case cleanDuplicates = "Eliminar duplicados"
        case cleanOld = "Limpiar archivos viejos"
    }
    
    public func organizeDesktop() -> String {
        return organizeDirectory(path: NSHomeDirectory() + "/Desktop", rule: .byType)
    }
    
    public func organizeDownloads() -> String {
        return organizeDirectory(path: NSHomeDirectory() + "/Downloads", rule: .byDate)
    }
    
    public func organizeDirectory(path: String, rule: OrganizeRule) -> String {
        let url = URL(fileURLWithPath: path)
        guard let files = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return "No se pudo acceder al directorio."
        }
        
        var moved = 0
        var skipped = 0
        
        for file in files {
            let name = file.lastPathComponent
            if name.hasPrefix(".") || name == "MACRON" { skipped += 1; continue }
            
            let destFolder: String
            switch rule {
            case .byType:
                destFolder = folderForType(file.pathExtension)
            case .byDate:
                let attrs = try? FileManager.default.attributesOfItem(atPath: file.path)
                let date = attrs?[.creationDate] as? Date ?? Date()
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM"
                destFolder = fmt.string(from: date)
            case .bySize:
                let attrs = try? FileManager.default.attributesOfItem(atPath: file.path)
                let size = (attrs?[.size] as? NSNumber)?.intValue ?? 0
                destFolder = size > 10_000_000 ? "Grandes" : "Pequenos"
            case .cleanDuplicates:
                continue
            case .cleanOld:
                continue
            }
            
            let destDir = url.appendingPathComponent(destFolder)
            try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            let dest = destDir.appendingPathComponent(name)
            
            do {
                try FileManager.default.moveItem(at: file, to: dest)
                moved += 1
            } catch {
                skipped += 1
            }
        }
        
        return "Organizacion completada: " + String(moved) + " archivos movidos, " + String(skipped) + " omitidos."
    }
    
    public func cleanOldFiles(days: Int = 30) -> String {
        let downloads = URL(fileURLWithPath: NSHomeDirectory() + "/Downloads")
        guard let files = try? FileManager.default.contentsOfDirectory(at: downloads, includingPropertiesForKeys: [.creationDateKey]) else {
            return "Error accediendo a Downloads."
        }
        
        let cutoff = Date().addingTimeInterval(TimeInterval(-days * 86400))
        var deleted = 0
        
        for file in files {
            let attrs = try? FileManager.default.attributesOfItem(atPath: file.path)
            let date = attrs?[.creationDate] as? Date ?? Date()
            if date < cutoff {
                try? FileManager.default.removeItem(at: file)
                deleted += 1
            }
        }
        
        return String(deleted) + " archivos antiguos eliminados de Downloads."
    }
    
    private func folderForType(_ ext: String) -> String {
        let images = ["jpg", "jpeg", "png", "gif", "webp", "heic"]
        let docs = ["pdf", "doc", "docx", "txt", "md", "rtf"]
        let videos = ["mp4", "mov", "avi", "mkv"]
        let audio = ["mp3", "m4a", "wav", "aac"]
        let archives = ["zip", "rar", "7z", "tar", "gz"]
        let code = ["swift", "py", "js", "html", "css", "json", "xml"]
        
        let lower = ext.lowercased()
        if images.contains(lower) { return "Imagenes" }
        if docs.contains(lower) { return "Documentos" }
        if videos.contains(lower) { return "Videos" }
        if audio.contains(lower) { return "Audio" }
        if archives.contains(lower) { return "Archivos" }
        if code.contains(lower) { return "Codigo" }
        return "Otros"
    }
}
