import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Crear ícono en la barra de menú
        statusItem = NSStatusBar.shared.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "◉ MACRON"
        
        // Crear menú
        let menu = NSMenu()
        
        let voiceItem = NSMenuItem(title: "🎤 Activar Voz", action: #selector(activateVoice), keyEquivalent: "v")
        menu.addItem(voiceItem)
        
        let chatItem = NSMenuItem(title: "💬 Chat", action: #selector(openChat), keyEquivalent: "c")
        menu.addItem(chatItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let statusItem = NSMenuItem(title: "📊 Estado", action: #selector(showStatus), keyEquivalent: "s")
        menu.addItem(statusItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "❌ Salir", action: #selector(quit), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        self.statusItem?.menu = menu
    }
    
    @objc func activateVoice() {
        runScript("from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator(); m.process_voice_command()")
    }
    
    @objc func openChat() {
        runScript("from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator(); print('MACRON Chat activo')")
    }
    
    @objc func showStatus() {
        runScript("from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator(); import json; print(json.dumps(m.status(), indent=2))")
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
    
    func runScript(_ script: String) {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "cd ~/Documents/MACRON && source venv/bin/activate && python3 -c '\(script)'"]
        task.launch()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
