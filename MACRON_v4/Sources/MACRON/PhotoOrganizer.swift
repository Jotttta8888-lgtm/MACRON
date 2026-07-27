import Foundation

class PhotoOrganizer {
    static let shared = PhotoOrganizer()
    
    func organizePhotos(in path: String) -> String {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: path) else { return "Error leyendo directorio" }
        var moved = 0
        for file in files {
            let ext = (file as NSString).pathExtension.lowercased()
            guard ["jpg", "jpeg", "png", "heic"].contains(ext) else { continue }
            let fullPath = path + "/" + file
            guard let attrs = try? fm.attributesOfItem(atPath: fullPath),
                  let date = attrs[.creationDate] as? Date else { continue }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM"
            let folder = path + "/" + formatter.string(from: date)
            try? fm.createDirectory(atPath: folder, withIntermediateDirectories: true)
            try? fm.moveItem(atPath: fullPath, toPath: folder + "/" + file)
            moved += 1
        }
        return "Fotos organizadas: " + String(moved)
    }
    
    func findPhotosByDate(year: Int, month: Int, in path: String) -> [String] {
        let fm = FileManager.default
        let targetFolder = String(format: "%04d/%02d", year, month)
        let fullPath = path + "/" + targetFolder
        guard let files = try? fm.contentsOfDirectory(atPath: fullPath) else { return [] }
        return files.filter { ["jpg", "jpeg", "png", "heic"].contains(($0 as NSString).pathExtension.lowercased()) }.map { fullPath + "/" + $0 }
    }
}
