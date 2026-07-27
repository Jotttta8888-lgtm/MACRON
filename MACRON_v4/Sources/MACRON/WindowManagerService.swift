import Foundation
import AppKit

class WindowManagerService {
    static let shared = WindowManagerService()
    
    func tileLeft() {
        let script = """
        tell application "System Events"
            tell process (name of first application process whose frontmost is true)
                set position of front window to {0, 25}
                set size of front window to {960, 1055}
            end tell
        end tell
        """
        runAppleScript(script)
    }
    
    func tileRight() {
        let script = """
        tell application "System Events"
            tell process (name of first application process whose frontmost is true)
                set position of front window to {960, 25}
                set size of front window to {960, 1055}
            end tell
        end tell
        """
        runAppleScript(script)
    }
    
    func maximize() {
        let script = """
        tell application "System Events"
            tell process (name of first application process whose frontmost is true)
                set position of front window to {0, 25}
                set size of front window to {1920, 1055}
            end tell
        end tell
        """
        runAppleScript(script)
    }
    
    private func runAppleScript(_ source: String) {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return }
        script.executeAndReturnError(&errorInfo)
    }
}
