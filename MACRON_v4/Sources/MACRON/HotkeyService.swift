import Cocoa
import Carbon

private var eventHandlerRef: EventHandlerRef?
private var hotKeyRef: EventHotKeyRef?

class HotkeyService {
    static let shared = HotkeyService()
    
    func startMonitoring() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, _ -> OSStatus in
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                if hkID.id == 1 {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .showVoiceAction, object: nil)
                    }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
        
        var gHotKeyID = EventHotKeyID(signature: FourCharCode(0x4D43524E), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_M),
            UInt32(cmdKey | shiftKey),
            gHotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        print("[Hotkey] Cmd+Shift+M registrado via Carbon")
    }
    
    func stopMonitoring() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
}
