import Foundation

class PythonREPLService {
    static let shared = PythonREPLService()
    
    func execute(_ code: String, completion: @escaping (String) -> Void) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        task.arguments = ["-c", code]
        let pipe = Pipe()
        let errPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errPipe
        task.terminationHandler = { _ in
            let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            completion(err.isEmpty ? out : "ERROR:\n" + err + "\nOUTPUT:\n" + out)
        }
        try? task.run()
    }
}
