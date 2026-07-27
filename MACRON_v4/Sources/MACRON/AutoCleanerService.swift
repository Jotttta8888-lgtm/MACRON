import Foundation

class AutoCleanerService {
    static let shared = AutoCleanerService()
    
    func cleanCaches() -> String {
        let paths = [
            NSHomeDirectory() + "/Library/Caches",
            NSHomeDirectory() + "/Library/Logs"
        ]
        var freed: Int64 = 0
        for path in paths {
            let fm = FileManager.default
            guard let items = try? fm.contentsOfDirectory(atPath: path) else { continue }
            for item in items {
                let full = path + "/" + item
                guard let attrs = try? fm.attributesOfItem(atPath: full),
                      let size = attrs[.size] as? Int64 else { continue }
                try? fm.removeItem(atPath: full)
                freed += size
            }
        }
        let mb = freed / 1024 / 1024
        NotificationService.shared.send(title: "MACRON Cleaner", body: "Liberados: " + String(mb) + " MB")
        return "Liberados: " + String(mb) + " MB"
    }
    
    func cleanDownloads() -> String {
        let path = NSHomeDirectory() + "/Downloads"
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(atPath: path) else { return "Error" }
        var removed = 0
        for item in items {
            let full = path + "/" + item
            var isDir: ObjCBool = false
            fm.fileExists(atPath: full, isDirectory: &isDir)
            if !isDir.boolValue {
                let ext = (item as NSString).pathExtension.lowercased()
                if ["dmg", "zip", "pkg"].contains(ext) {
                    try? fm.removeItem(atPath: full)
                    removed += 1
                }
            }
        }
        return "Archivos eliminados: " + String(removed)
    }
}
