import Foundation

class AutoBackupService {
    static let shared = AutoBackupService()
    
    func backupNow() -> String {
        let source = NSHomeDirectory() + "/Documents/MACRON"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = dateFormatter.string(from: Date())
        let zipName = "MACRON_backup_" + timestamp + ".zip"
        let desktop = NSHomeDirectory() + "/Desktop/" + zipName
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        task.arguments = ["-r", "-q", desktop, source]
        try? task.run()
        task.waitUntilExit()
        
        if task.terminationStatus == 0 {
            NotificationService.shared.send(title: "MACRON Backup", body: "Backup creado: " + zipName)
            return "Backup creado en Desktop: " + zipName
        }
        return "Error creando backup"
    }
}
