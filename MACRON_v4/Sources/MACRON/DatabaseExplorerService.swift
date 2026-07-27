import Foundation

class DatabaseExplorerService {
    static let shared = DatabaseExplorerService()
    
    func readJSON(_ path: String) -> [[String: Any]]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) else { return nil }
        if let dict = json as? [String: Any] { return [dict] }
        if let array = json as? [[String: Any]] { return array }
        return nil
    }
    
    func readCSV(_ path: String) -> [[String: String]]? {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard let header = lines.first else { return nil }
        let keys = header.components(separatedBy: ",")
        return lines.dropFirst().map { line in
            let values = line.components(separatedBy: ",")
            return Dictionary(uniqueKeysWithValues: zip(keys, values))
        }
    }
    
    func querySQLite(_ path: String, sql: String) -> [[String: String]]? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        task.arguments = [path, "-header", "-csv", sql]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard let header = lines.first else { return nil }
        let keys = header.components(separatedBy: ",")
        return lines.dropFirst().map { line in
            let values = line.components(separatedBy: ",")
            return Dictionary(uniqueKeysWithValues: zip(keys, values))
        }
    }
}
