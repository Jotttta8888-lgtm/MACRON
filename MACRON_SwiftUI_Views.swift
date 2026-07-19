//
//  MACRON_SwiftUI_Views.swift
//  Vistas principales de la interfaz SwiftUI
//

import SwiftUI
import AppKit

// MARK: - Content View (Contenedor principal)

struct ContentView: View {
    @EnvironmentObject var state: MacronState

    var body: some View {
        NavigationSplitView {
            Sidebar()
                .frame(minWidth: 220)
        } detail: {
            DetailView()
        }
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                StatusBar()
            }
        }
    }
}

// MARK: - Sidebar

struct Sidebar: View {
    @EnvironmentObject var state: MacronState

    var body: some View {
        List(selection: $state.selectedTab) {
            Section("Principal") {
                Label("Dashboard", systemImage: "gauge.with.dots.needle.67percent")
                    .tag(0)
                Label("RAG Archivos", systemImage: "doc.text.magnifyingglass")
                    .tag(1)
                Label("Planificacion", systemImage: "list.bullet.clipboard")
                    .tag(2)
                Label("Rutinas", systemImage: "clock.arrow.circlepath")
                    .tag(3)
            }

            Section("IA Avanzada") {
                Label("Chain-of-Thought", systemImage: "brain.head.profile")
                    .tag(4)
                Label("Vault", systemImage: "lock.shield")
                    .tag(5)
                Label("Transcripcion", systemImage: "waveform")
                    .tag(6)
                Label("Code Complete", systemImage: "chevron.left.forwardslash.chevron.right")
                    .tag(7)
            }

            Section("Seguridad") {
                Label("Intrusos", systemImage: "eye.trianglebadge.exclamationmark")
                    .tag(8)
                Label("FaceRec", systemImage: "face.smiling")
                    .tag(9)
            }

            Section("Conectividad") {
                Label("Notion", systemImage: "square.grid.2x2")
                    .tag(10)
                Label("Multi-Device", systemImage: "network")
                    .tag(11)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MACRON")
    }
}

// MARK: - Detail View

struct DetailView: View {
    @EnvironmentObject var state: MacronState

    var body: some View {
        Group {
            switch state.selectedTab {
            case 0: DashboardView()
            case 1: RAGView()
            case 2: PlanningView()
            case 3: RutinasView()
            case 4: CoTView()
            case 5: VaultView()
            case 6: TranscriptionView()
            case 7: CodeCompleteView()
            case 8: IntrusionView()
            case 9: FaceRecView()
            case 10: NotionView()
            case 11: MultiDeviceView()
            default: DashboardView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    @EnvironmentObject var state: MacronState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(state.statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { state.isRunning ? state.stopMacron() : state.startMacron() }) {
                        Label(state.isRunning ? "Detener" : "Iniciar", 
                              systemImage: state.isRunning ? "stop.fill" : "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(state.isRunning ? .red : .green)
                }
                .padding(.horizontal)

                // Modulos Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                    ForEach(state.modules) { module in
                        ModuleCard(module: module)
                    }
                }
                .padding()

                // Notificaciones recientes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notificaciones Recientes")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(state.notifications.prefix(5)) { notif in
                        NotificationRow(notif: notif)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ModuleCard: View {
    let module: MacronState.ModuleStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: module.icon)
                    .font(.title2)
                    .foregroundColor(module.isActive ? .accentColor : .secondary)
                Spacer()
                Circle()
                    .fill(module.isActive ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }

            Text(module.name)
                .font(.headline)

            Text(module.isActive ? "Activo" : "Inactivo")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(height: 100)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct NotificationRow: View {
    let notif: MacronState.MacronNotification

    var iconColor: Color {
        switch notif.type {
        case .success: return .green
        case .warning: return .orange
        case .alert: return .red
        case .info: return .blue
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(notif.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(notif.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(notif.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - RAG View

struct RAGView: View {
    @State private var filePath = ""
    @State private var searchQuery = ""
    @State private var results: [String] = []
    @EnvironmentObject var state: MacronState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RAG - Archivos Indexados")
                .font(.title)
                .fontWeight(.bold)

            // Indexar
            VStack(alignment: .leading, spacing: 8) {
                Text("Indexar Archivo")
                    .font(.headline)
                HStack {
                    TextField("Ruta del archivo", text: $filePath)
                        .textFieldStyle(.roundedBorder)
                    Button("Indexar") {
                        state.executeCommand("macron.rag.index_file('\(filePath)')")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            // Buscar
            VStack(alignment: .leading, spacing: 8) {
                Text("Buscar")
                    .font(.headline)
                HStack {
                    TextField("Query de busqueda", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                    Button("Buscar") {
                        state.executeCommand("macron.rag.search('\(searchQuery)')")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            // Resultados
            List(results, id: \.self) { result in
                Text(result)
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Planning View

struct PlanningView: View {
    @State private var planName = ""
    @State private var planDesc = ""
    @State private var steps = ""
    @EnvironmentObject var state: MacronState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Planificacion Verificada")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("Nuevo Plan")
                    .font(.headline)
                TextField("Nombre", text: $planName)
                    .textFieldStyle(.roundedBorder)
                TextField("Descripcion", text: $planDesc)
                    .textFieldStyle(.roundedBorder)
                TextEditor(text: $steps)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
                Button("Crear Plan") {
                    let stepsList = steps.split(separator: "\n").map { String($0) }
                    state.executeCommand("macron.planning.create('\(planName)', '\(planDesc)', \(stepsList))")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Rutinas View

struct RutinasView: View {
    @State private var name = ""
    @State private var cron = "0 * * * *"
    @State private var actionType = "shell"
    @EnvironmentObject var state: MacronState

    let actionTypes = ["shell", "python", "notification", "backup", "open_app"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rutinas Programadas")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("Nueva Rutina")
                    .font(.headline)
                TextField("Nombre", text: $name)
                    .textFieldStyle(.roundedBorder)
                TextField("Cron (ej: 0 2 * * *)", text: $cron)
                    .textFieldStyle(.roundedBorder)
                Picker("Tipo", selection: $actionType) {
                    ForEach(actionTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Button("Crear") {
                        state.executeCommand("macron.rutinas.create('\(name)', '', '\(cron)', '\(actionType)', {})")
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Iniciar Scheduler") {
                        state.executeCommand("macron.rutinas.start_scheduler()")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Vault View

struct VaultView: View {
    @State private var masterPwd = ""
    @State private var key = ""
    @State private var value = ""
    @State private var isSetup = false
    @EnvironmentObject var state: MacronState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vault - Caja Fuerte")
                .font(.title)
                .fontWeight(.bold)

            if !isSetup {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configurar Vault")
                        .font(.headline)
                    SecureField("Password Maestro", text: $masterPwd)
                        .textFieldStyle(.roundedBorder)
                    Button("Configurar") {
                        state.executeCommand("macron.vault.setup('\(masterPwd)')")
                        isSetup = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Almacenar Valor")
                        .font(.headline)
                    TextField("Clave", text: $key)
                        .textFieldStyle(.roundedBorder)
                    TextField("Valor", text: $value)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $masterPwd)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Button("Guardar") {
                            state.executeCommand("macron.vault.store('\(key)', '\(value)', '\(masterPwd)')")
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Recuperar") {
                            state.executeCommand("macron.vault.retrieve('\(key)', '\(masterPwd)')")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Transcription View

struct TranscriptionView: View {
    @State private var audioPath = ""
    @State private var language = "es"
    @State private var isRecording = false
    @EnvironmentObject var state: MacronState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transcripcion de Audio")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("Transcribir Archivo")
                    .font(.headline)
                HStack {
                    TextField("Ruta del audio", text: $audioPath)
                        .textFieldStyle(.roundedBorder)
                    TextField("Idioma", text: $language)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
                Button("Transcribir") {
                    state.executeCommand("macron.transcription.transcribe('\(audioPath)', '\(language)')")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            // Grabar desde microfono
            VStack(alignment: .leading, spacing: 12) {
                Text("Grabar desde Microfono")
                    .font(.headline)
                Button(action: {
                    isRecording.toggle()
                    if isRecording {
                        state.executeCommand("macron.transcription.from_mic(10, '\(language)')")
                    }
                }) {
                    Label(isRecording ? "Detener" : "Grabar", 
                          systemImage: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
                .tint(isRecording ? .red : .accentColor)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Code Complete View

struct CodeCompleteView: View {
    @State private var code = ""
    @State private var language = "python"
    @State private var result = ""
    @EnvironmentObject var state: MacronState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Autocompletado de Codigo")
                .font(.title)
                .fontWeight(.bold)

            HStack {
                TextField("Lenguaje", text: $language)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                Spacer()
                Button("Sugerir") {
                    state.executeCommand("macron.code.suggest('\(code)', '\(language)')")
                }
                .buttonStyle(.borderedProminent)
                Button("Explicar") {
                    state.executeCommand("macron.code.explain('\(code)', '\(language)')")
                }
                .buttonStyle(.bordered)
            }

            TextEditor(text: $code)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))

            if !result.isEmpty {
                VStack(alignment: .leading) {
                    Text("Resultado:")
                        .font(.headline)
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Placeholder Views

struct CoTView: View {
    @EnvironmentObject var state: MacronState
    var body: some View {
        PlaceholderView(title: "Chain-of-Thought", icon: "brain.head.profile", 
                       description: "Razonamiento paso a paso visible y exportable a Markdown.")
    }
}

struct IntrusionView: View {
    @EnvironmentObject var state: MacronState
    var body: some View {
        PlaceholderView(title: "Deteccion de Intrusos", icon: "eye.trianglebadge.exclamationmark",
                       description: "Monitoreo por camara con reconocimiento facial.")
    }
}

struct FaceRecView: View {
    @EnvironmentObject var state: MacronState
    var body: some View {
        PlaceholderView(title: "Reconocimiento Facial", icon: "face.smiling",
                       description: "Registro y reconocimiento de rostros con dlib.")
    }
}

struct NotionView: View {
    @EnvironmentObject var state: MacronState
    var body: some View {
        PlaceholderView(title: "Notion", icon: "square.grid.2x2",
                       description: "Integracion bidireccional con Notion API.")
    }
}

struct MultiDeviceView: View {
    @EnvironmentObject var state: MacronState
    var body: some View {
        PlaceholderView(title: "Multi-Dispositivo", icon: "network",
                       description: "Sincronizacion entre dispositivos Apple.")
    }
}

struct PlaceholderView: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @EnvironmentObject var state: MacronState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(state.isRunning ? .green : .secondary)
                Text("MACRON")
                    .fontWeight(.bold)
                Spacer()
                Circle()
                    .fill(state.isRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()

            Button("Abrir Dashboard") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Button(state.isRunning ? "Detener" : "Iniciar") {
                state.isRunning ? state.stopMacron() : state.startMacron()
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Divider()

            Button("Salir") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(width: 180)
    }
}

// MARK: - Status Bar

struct StatusBar: View {
    @EnvironmentObject var state: MacronState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cpu")
                .foregroundColor(state.isRunning ? .green : .secondary)
            Text(state.statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)

            if state.visualIntelligenceEnabled {
                Label("VI", systemImage: "eye")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
    }
}
