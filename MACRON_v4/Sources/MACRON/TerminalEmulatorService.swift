import Foundation

class TerminalEmulatorService {
    static let shared = TerminalEmulatorService()
    
    func execute(_ command: String, completion: @escaping (String) -> Void) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", command]
        let pipe = Pipe()
        let errPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errPipe
        task.terminationHandler = { _ in
            let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            completion(err.isEmpty ? out : out + "\n[ERROR]\n" + err)
        }
        try? task.run()
    }
}
