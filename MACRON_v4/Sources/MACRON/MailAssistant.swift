import Foundation

class MailAssistant: ObservableObject {
    static let shared = MailAssistant()
    @Published var unreadCount = 0
    @Published var urgentEmails: [String] = []
    
    func checkMail() {
        let script = """
        tell application "Mail"
            set unreadList to {}
            set urgentList to {}
            set inboxMsgs to messages of inbox whose read status is false
            repeat with msg in inboxMsgs
                set subj to subject of msg
                set sndr to sender of msg
                set end of unreadList to (subj & " | " & sndr)
                set lowerSubj to my lowerString(subj)
                if lowerSubj contains "urgente" or lowerSubj contains "urgent" or lowerSubj contains "asap" or lowerSubj contains "hoy" then
                    set end of urgentList to (subj & " | " & sndr)
                end if
            end repeat
            return {count of inboxMsgs, unreadList, urgentList}
        end tell
        
        on lowerString(str)
            set lowerStr to ""
            repeat with ch in str
                set lowerStr to lowerStr & (do shell script "echo " & quoted form of ch & " | tr '[:upper:]' '[:lower:]'")
            end repeat
            return lowerStr
        end lowerString
        """
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return }
        let result = appleScript.executeAndReturnError(&errorInfo)
        if let error = errorInfo {
            print("[MailAssistant] Error: " + String(describing: error))
            return
        }
        if result.descriptorType == typeAEList {
            if let countDesc = result.atIndex(1) {
                unreadCount = Int(countDesc.int32Value)
            }
            if let urgentDesc = result.atIndex(3) {
                var urgents: [String] = []
                for i in 1...urgentDesc.numberOfItems {
                    if let item = urgentDesc.atIndex(i)?.stringValue {
                        urgents.append(item)
                    }
                }
                urgentEmails = urgents
            }
        }
        if !urgentEmails.isEmpty {
            NotificationService.shared.send(title: "MACRON Mail", body: String(urgentEmails.count) + " emails urgentes")
        }
    }
}
