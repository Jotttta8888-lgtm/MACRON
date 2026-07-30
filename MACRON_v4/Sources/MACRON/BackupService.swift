import Foundation
public actor BackupService {
    public static let shared = BackupService()
    private init() {}
    public func createBackup() -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let macronDir = docs.appendingPathComponent("MACRON")
        let backupDir = docs.appendingPathComponent("MACRON_Backups/backup_\(Int(Date().timeIntervalSince1970))")
        try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        let files = ["VoiceClone","Recordings"]
        for f in files {
            let src = macronDir.appendingPathComponent(f)
            let dst = backupDir.appendingPathComponent(f)
            try? FileManager.default.copyItem(at: src, to: dst)
        }
        return "💾 Backup creado en: \(backupDir.path)"
    }
}
