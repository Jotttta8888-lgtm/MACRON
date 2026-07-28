import Foundation
import CryptoKit

class DuplicateFinderService: ObservableObject {
    static let shared = DuplicateFinderService()
    @Published var duplicates: [[DuplicateFile]] = []
    @Published var isScanning = false
    
    struct DuplicateFile: Identifiable {
        let id = UUID()
        let path: String
        let size: Int64
        let hash: String
    }
    
    func scanDirectory(_ path: String) {
        isScanning = true
        duplicates = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: path) else { isScanning = false; return }
        
        var filesByHash: [String: [DuplicateFile]] = [:]
        
        for case let file as String in enumerator {
            let fullPath = path + "/" + file
            var isDir: ObjCBool = false
            let exists = fm.fileExists(atPath: fullPath, isDirectory: &isDir)
            guard exists && !isDir.boolValue,
                  let attrs = try? fm.attributesOfItem(atPath: fullPath),
                  let size = attrs[.size] as? Int64 else { continue }
            
            let hash = computeHash(of: fullPath) ?? ""
            let dup = DuplicateFile(path: fullPath, size: size, hash: hash)
            filesByHash[hash, default: []].append(dup)
        }
        
        duplicates = filesByHash.values.filter { $0.count > 1 }
        isScanning = false
        NotificationService.shared.send(title: "MACRON Duplicates", body: "Encontrados " + String(duplicates.count) + " grupos de duplicados")
    }
    
    private func computeHash(of path: String) -> String? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func deleteFile(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
        NotificationService.shared.send(title: "MACRON Duplicates", body: "Eliminado: " + (path as NSString).lastPathComponent)
    }
}
