import Cocoa

class MenuBarService: NSObject {
    static let shared = MenuBarService()
    private var statusItem: NSStatusItem?
    private var backendItem: NSMenuItem?
    private var startItem: NSMenuItem?
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "MACRON")
        
        let menu = NSMenu()
        
        let openItem = NSMenuItem(title: "Abrir MACRON", action: #selector(openApp), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        
                let wakeItem = NSMenuItem(title: "Activar Wake Word", action: #selector(toggleWakeWord), keyEquivalent: "")
        wakeItem.target = self
        wakeItem.state = UserDefaults.standard.bool(forKey: "wakeWordEnabled") ? .on : .off
        menu.addItem(wakeItem)
        menu.addItem(NSMenuItem.separator())
        
        backendItem = NSMenuItem(title: "Backend: Verificando...", action: nil, keyEquivalent: "")
        menu.addItem(backendItem!)
        
        startItem = NSMenuItem(title: "Iniciar Backend", action: #selector(startBackend), keyEquivalent: "")
        startItem?.target = self
        menu.addItem(startItem!)
        
        menu.addItem(NSMenuItem.separator())
        
        let prefsItem = NSMenuItem(title: "Preferencias...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Salir", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in self.checkBackend() }
        checkBackend()
    }
    
    @objc private func openApp() {
        startBackendIfNeeded()
        // No forzar foco - el usuario ya activo la app desde el menu bar
    }
    
    @objc private func startBackend() {
        startBackendIfNeeded()
    }
    
    func startBackendIfNeeded() {
        let scriptPath = NSHomeDirectory() + "/Documents/MACRON/start_macron.sh"
        guard FileManager.default.fileExists(atPath: scriptPath) else { return }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [scriptPath]
        task.environment = ProcessInfo.processInfo.environment
        
        do {
            try task.run()
            NotificationService.shared.send(title: "MACRON", body: "Backend iniciando...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.checkBackend() }
        } catch {
            print("[MenuBar] Error iniciando backend: \(error)")
        }
    }
    
    @objc private func openPreferences() {
        NotificationCenter.default.post(name: .showSettings, object: nil)
        openApp()
    }
    
    @objc private func toggleWakeWord() {
        let enabled = !UserDefaults.standard.bool(forKey: "wakeWordEnabled")
        UserDefaults.standard.set(enabled, forKey: "wakeWordEnabled")
        if enabled {
            WakeWordService().startListening()
            NotificationService.shared.send(title: "MACRON", body: "Wake Word activado")
        } else {
            WakeWordService().stopListening()
            NotificationService.shared.send(title: "MACRON", body: "Wake Word desactivado")
        }
        setup() // refrescar menu
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func checkBackend() {
        guard let bItem = backendItem, let sItem = startItem else { return }
        URLSession.shared.dataTask(with: URL(string: "http://localhost:5001/api/health")!) { _, response, _ in
            DispatchQueue.main.async {
                if let r = response as? HTTPURLResponse, r.statusCode == 200 {
                    bItem.title = "Backend: Online"
                    sItem.isHidden = true
                } else {
                    bItem.title = "Backend: Offline"
                    sItem.isHidden = false
                }
            }
        }.resume()
    }
}
