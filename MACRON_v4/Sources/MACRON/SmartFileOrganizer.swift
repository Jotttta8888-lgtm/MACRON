import Foundation

class SmartFileOrganizer {
    static let shared = SmartFileOrganizer()
    
    let categories: [String: [String]] = [
        "Imagenes": ["jpg", "jpeg", "png", "gif", "heic", "webp", "svg"],
        "Documentos": ["pdf", "doc", "docx", "txt", "rtf", "pages", "md"],
        "HojasDeCalculo": ["xls", "xlsx", "csv", "numbers"],
        "Presentaciones": ["ppt", "pptx", "key"],
        "Videos": ["mp4", "mov", "avi", "mkv", "wmv"],
        "Audio": ["mp3", "wav", "aac", "m4a", "flac"],
        "Comprimidos": ["zip", "rar", "7z", "tar", "gz"],
        "Apps": ["dmg", "pkg", "app"],
        "Codigo": ["swift", "py", "js", "html", "css", "json", "xml"]
    ]
    
    func organizeDirectory(_ path: String) -> String {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: path) else { return "Error leyendo directorio" }
        var moved = 0
        for file in files {
            let ext = (file as NSString).pathExtension.lowercased()
            guard let category = categories.first(where: { $0.value.contains(ext) })?.key else { continue }
            let categoryPath = path + "/" + category
            try? fm.createDirectory(atPath: categoryPath, withIntermediateDirectories: true)
            let source = path + "/" + file
            let dest = categoryPath + "/" + file
            try? fm.moveItem(atPath: source, toPath: dest)
            moved += 1
        }
        return "Organizados: \(moved) archivos"
    }
    
    func findDuplicates(in path: String) -> [[String]] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: path) else { return [] }
        var hashes: [String: [String]] = [:]
        for file in files {
            let fullPath = path + "/" + file
            guard let data = fm.contents(atPath: fullPath) else { continue }
            let hash = data.base64EncodedString().prefix(16)
            hashes[String(hash), default: []].append(file)
        }
        return hashes.values.filter { $0.count > 1 }
    }
    
    func findLargeFiles(in path: String, minMB: Int = 100) -> [String] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: path) else { return [] }
        var large: [String] = []
        for file in files {
            let fullPath = path + "/" + file
            guard let attrs = try? fm.attributesOfItem(atPath: fullPath),
                  let size = attrs[.size] as? Int64 else { continue }
            if size > minMB * 1024 * 1024 { large.append(file) }
        }
        return large
    }
}
