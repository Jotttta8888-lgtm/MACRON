import Foundation
import CryptoKit

class EncryptedVaultService: ObservableObject {
    static let shared = EncryptedVaultService()
    @Published var isUnlocked = false
    private let vaultPath = NSHomeDirectory() + "/Documents/MACRON/vault"
    
    func unlock() { isUnlocked = true }
    func lock() { isUnlocked = false }
    
    func saveFile(name: String, content: String, password: String) {
        let data = content.data(using: .utf8) ?? Data()
        let key = SymmetricKey(data: SHA256.hash(data: password.data(using: .utf8)!).compactMap { $0 })
        do {
            let sealed = try AES.GCM.seal(data, using: key)
            let fm = FileManager.default
            try? fm.createDirectory(atPath: vaultPath, withIntermediateDirectories: true)
            try sealed.combined?.write(to: URL(fileURLWithPath: vaultPath + "/" + name + ".enc"))
            NotificationService.shared.send(title: "MACRON Vault", body: "Archivo encriptado: " + name)
        } catch {
            print("Error encriptando: " + String(describing: error))
        }
    }
    
    func readFile(name: String, password: String) -> String? {
        let key = SymmetricKey(data: SHA256.hash(data: password.data(using: .utf8)!).compactMap { $0 })
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: vaultPath + "/" + name + ".enc"))
            let sealed = try AES.GCM.SealedBox(combined: data)
            let decrypted = try AES.GCM.open(sealed, using: key)
            return String(data: decrypted, encoding: .utf8)
        } catch { return nil }
    }
}
