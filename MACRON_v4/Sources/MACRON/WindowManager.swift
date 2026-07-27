import Cocoa
import SwiftUI

class WindowManager: NSObject, NSWindowDelegate {
    static let shared = WindowManager()
    private var floating = false
    
    func setup(window: NSWindow?) {
        guard let window = window else { return }
        window.delegate = self
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.fullScreenAuxiliary, .transient]
    }
    
    func setFloating(_ enabled: Bool) {
        floating = enabled
        guard let window = NSApp.windows.first else { return }
        if enabled {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            window.level = .normal
            window.collectionBehavior = [.managed, .fullScreenAuxiliary]
        }
    }
    
    func toggleFloating() {
        setFloating(!floating)
    }
}
