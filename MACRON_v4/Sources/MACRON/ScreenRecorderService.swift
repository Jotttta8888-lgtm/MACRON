import Foundation

class ScreenRecorderService {
    static let shared = ScreenRecorderService()
    
    func startRecording(to path: String? = nil) -> String {
        let output = path ?? (NSHomeDirectory() + "/Desktop/MACRON_recording_\(Int(Date().timeIntervalSince1970)).mov")
        let script = """
        tell application "QuickTime Player"
            start (new screen recording)
            delay 1
            return "Recording started"
        end tell
        """
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return "Error" }
        let result = appleScript.executeAndReturnError(&errorInfo)
        NotificationService.shared.send(title: "MACRON", body: "Grabacion iniciada")
        return result.stringValue ?? "OK"
    }
    
    func stopRecording() -> String {
        let script = """
        tell application "QuickTime Player"
            stop (document 1)
            return "Recording stopped"
        end tell
        """
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return "Error" }
        let result = appleScript.executeAndReturnError(&errorInfo)
        NotificationService.shared.send(title: "MACRON", body: "Grabacion detenida")
        return result.stringValue ?? "OK"
    }
}
