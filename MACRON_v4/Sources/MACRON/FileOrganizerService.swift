import Foundation
public actor FileOrganizerService {
    public static let shared = FileOrganizerService()
    private init() {}
    public func organizeDesktop() -> String {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let files = (try? FileManager.default.contentsOfDirectory(at: desktop, includingPropertiesForKeys: nil)) ?? []
        var moved = 0
        for url in files {
            let ext = url.pathExtension.lowercased()
            var destDir: URL?
            if ["jpg","jpeg","png","heic","gif"].contains(ext) { destDir = docs.appendingPathComponent("Imagenes") }
            else if ["pdf","doc","docx","txt","pages"].contains(ext) { destDir = docs.appendingPathComponent("Documentos") }
            else if ["mp4","mov","avi"].contains(ext) { destDir = docs.appendingPathComponent("Videos") }
            else if ["zip","tar","gz","dmg"].contains(ext) { destDir = docs.appendingPathComponent("Archivos") }
            if let dest = destDir {
                try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
                let target = dest.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.moveItem(at: url, to: target)
                moved += 1
            }
        }
        return "📁 Escritorio organizado. \(moved) archivos movidos a Documentos/."
    }
}
