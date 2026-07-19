//
//  MACRON_SwiftUI_App.swift
//  MACRON - Agente IA Local para macOS
//
//  Version: 2.0
//  Fecha: 2026-07-17
//  Requiere: macOS 27 Golden Gate (minimo macOS 14 Sonoma)
//

import SwiftUI
import AppKit
import Combine

// MARK: - Modelo de Datos Compartido

@MainActor
class MacronState: ObservableObject {
    @Published var isRunning = false
    @Published var statusMessage = "MACRON inactivo"
    @Published var modules: [ModuleStatus] = []
    @Published var logs: [LogEntry] = []
    @Published var notifications: [MacronNotification] = []
    @Published var selectedTab = 0
    @Published var showSettings = false

    // macOS 27 Golden Gate - Visual Intelligence
    @Published var visualIntelligenceEnabled = false
    @Published var selectedScreenRegion: NSRect? = nil

    private var pythonBridge: PythonBridge?
    private var timer: Timer?

    struct ModuleStatus: Identifiable {
        let id = UUID()
        let name: String
        let isActive: Bool
        let icon: String
    }

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: String
        let message: String
        let module: String
    }

    struct MacronNotification: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let timestamp: Date
        let type: NotificationType

        enum NotificationType {
            case info, warning, alert, success
        }
    }

    func startMacron() {
        pythonBridge = PythonBridge()
        isRunning = true
        statusMessage = "MACRON activo - Apple Silicon optimizado"

        // Cargar estado de modulos
        modules = [
            ModuleStatus(name: "RAG Archivos", isActive: true, icon: "doc.text.magnifyingglass"),
            ModuleStatus(name: "Planificacion", isActive: true, icon: "list.bullet.clipboard"),
            ModuleStatus(name: "Chain-of-Thought", isActive: true, icon: "brain.head.profile"),
            ModuleStatus(name: "Rutinas", isActive: true, icon: "clock.arrow.circlepath"),
            ModuleStatus(name: "FaceRec", isActive: false, icon: "face.smiling"),
            ModuleStatus(name: "Notion", isActive: false, icon: "square.grid.2x2"),
            ModuleStatus(name: "Multi-Device", isActive: true, icon: "network"),
            ModuleStatus(name: "Intrusos", isActive: false, icon: "eye.trianglebadge.exclamationmark"),
            ModuleStatus(name: "Vault", isActive: true, icon: "lock.shield"),
            ModuleStatus(name: "Transcripcion", isActive: false, icon: "waveform"),
            ModuleStatus(name: "CodeComplete", isActive: false, icon: "chevron.left.forwardslash.chevron.right")
        ]

        // Timer para actualizar estado
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateStatus()
            }
        }

        addNotification(title: "MACRON Iniciado", message: "Agente IA local activo", type: .success)
    }

    func stopMacron() {
        timer?.invalidate()
        pythonBridge = nil
        isRunning = false
        statusMessage = "MACRON detenido"
    }

    func updateStatus() {
        // Actualizar desde Python bridge
        if let bridge = pythonBridge {
            bridge.getStatus { status in
                DispatchQueue.main.async {
                    self.statusMessage = status["message"] as? String ?? "Actualizando..."
                }
            }
        }
    }

    func addNotification(title: String, message: String, type: MacronNotification.NotificationType) {
        let notif = MacronNotification(title: title, message: message, timestamp: Date(), type: type)
        notifications.insert(notif, at: 0)

        // macOS nativo notification
        let nsNotif = NSUserNotification()
        nsNotif.title = title
        nsNotif.informativeText = message
        nsNotif.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(nsNotif)
    }

    func executeCommand(_ command: String) {
        logs.append(LogEntry(timestamp: Date(), level: "CMD", message: command, module: "UI"))
        pythonBridge?.execute(command)
    }
}

// MARK: - Python Bridge

class PythonBridge {
    private var process: Process?
    private var pipe: Pipe?

    init() {
        startPythonProcess()
    }

    private func startPythonProcess() {
        process = Process()
        process?.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process?.arguments = ["python3", "-c", "from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator(); import server"]

        pipe = Pipe()
        process?.standardOutput = pipe
        process?.standardError = pipe

        do {
            try process?.run()
        } catch {
            print("Error iniciando Python: \(error)")
        }
    }

    func execute(_ command: String) {
        // Enviar comando al proceso Python via socket/pipe
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["python3", "-c", command]
        try? task.run()
    }

    func getStatus(completion: @escaping ([String: Any]) -> Void) {
        // Llamar a API REST del backend Python
        completion(["message": "MACRON ejecutandose"])
    }

    deinit {
        process?.terminate()
    }
}

// MARK: - App Principal

@main
struct MacronApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var state = MacronState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            MacronCommands(state: state)
        }

        // Menu bar extra
        MenuBarExtra("MACRON", systemImage: "cpu") {
            MenuBarView()
                .environmentObject(state)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configurar apariencia
        NSApp.appearance = NSAppearance(named: .darkAqua)

        // macOS 27 Golden Gate - Liquid Glass
        if #available(macOS 27.0, *) {
            // Activar Liquid Glass mejorado
            NSWindow.allowsAutomaticWindowTabbing = false
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Mantener en menu bar
    }
}

// MARK: - Commands

struct MacronCommands: Commands {
    @ObservedObject var state: MacronState

    var body: some Commands {
        CommandMenu("MACRON") {
            Button("Iniciar Agente") {
                state.startMacron()
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("Detener Agente") {
                state.stopMacron()
            }
            .keyboardShortcut(".", modifiers: [.command, .shift])

            Divider()

            Button("Abrir Vault") {
                state.selectedTab = 5
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])

            Button("Nueva Transcripcion") {
                state.selectedTab = 6
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Divider()

            // macOS 27 - Visual Intelligence
            if #available(macOS 27.0, *) {
                Button("Visual Intelligence") {
                    state.visualIntelligenceEnabled.toggle()
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }
        }

        CommandGroup(after: .windowArrangement) {
            Button("Dashboard") {
                state.selectedTab = 0
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("RAG") {
                state.selectedTab = 1
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("Rutinas") {
                state.selectedTab = 3
            }
            .keyboardShortcut("3", modifiers: .command)
        }
    }
}
