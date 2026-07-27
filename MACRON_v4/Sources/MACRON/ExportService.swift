import Foundation
class ExportService {
    static let shared = ExportService()
    private let historyPath = NSHomeDirectory() + "/Documents/MACRON/data/chat_history.json"
    func exportToJSON() -> URL? {
        let dest = NSHomeDirectory() + "/Documents/MACRON_Export_\(Int(Date().timeIntervalSince1970)).json"
        do { try FileManager.default.copyItem(atPath: historyPath, toPath: dest); return URL(fileURLWithPath: dest) }
        catch { return nil }
    }
    func exportToCSV() -> URL? {
        guard let data = FileManager.default.contents(atPath: historyPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String:Any]] else { return nil }
        var csv = "timestamp,role,message\n"
        for e in json {
            let ts = e["timestamp"] as? String ?? ""
            let role = e["role"] as? String ?? ""
            let msg = (e["message"] as? String ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(ts)\",\"\(role)\",\"\(msg)\"\n"
        }
        let dest = NSHomeDirectory() + "/Documents/MACRON_Export_\(Int(Date().timeIntervalSince1970)).csv"
        do { try csv.write(toFile: dest, atomically: true, encoding: .utf8); return URL(fileURLWithPath: dest) }
        catch { return nil }
    }
    func exportToPDF() -> URL? {
        guard let data = FileManager.default.contents(atPath: historyPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String:Any]] else { return nil }
        var html = "<html><head><meta charset='UTF-8'><style>body{font-family:system-ui;padding:40px;max-width:800px;margin:0 auto;}h1{color:#0a84ff;}.msg{padding:12px;margin:8px 0;border-radius:12px;}.user{background:#0a84ff;color:white;}.bot{background:#1c1c1e;color:#f5f5f7;}</style></head><body><h1>MACRON - Historial</h1>"
        for e in json {
            let role = e["role"] as? String ?? ""
            let msg = e["message"] as? String ?? ""
            html += "<div class='msg \(role == "user" ? "user" : "bot")'><strong>\(role.uppercased())</strong><br>\(msg)</div>"
        }
        html += "</body></html>"
        let dest = NSHomeDirectory() + "/Documents/MACRON_Export_\(Int(Date().timeIntervalSince1970)).html"
        do { try html.write(toFile: dest, atomically: true, encoding: .utf8); return URL(fileURLWithPath: dest) }
        catch { return nil }
    }
}
