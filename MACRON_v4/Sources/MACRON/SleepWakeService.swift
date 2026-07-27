import Foundation
import AppKit

class SleepWakeService: ObservableObject {
    @Published var isSleeping = false
    
    func startMonitoring() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(willSleep),
            name: NSWorkspace.willSleepNotification, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification, object: nil
        )
    }
    
    @objc private func willSleep() {
        isSleeping = true
        print("[Sleep] Mac va a dormir")
    }
    
    @objc private func didWake() {
        isSleeping = false
        print("[Wake] Mac despertó")
    }
}
