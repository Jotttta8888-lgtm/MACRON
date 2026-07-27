import Foundation

class SpotlightEnhancerService {
    static let shared = SpotlightEnhancerService()
    
    func search(_ query: String) -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        task.arguments = [query]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
    
    func findRecentFiles(days: Int = 7) -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        task.arguments = ["-onlyin", NSHomeDirectory(), "-time", String(days)]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
}
