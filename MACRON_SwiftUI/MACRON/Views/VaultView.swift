import SwiftUI
struct VaultView: View {
    @ObservedObject var orchestrator: MacronOrchestrator
    @State private var password = "", key = "", value = "", result = ""
    var body: some View {
        VStack(spacing: 20) {
            Text("Vault").font(.title2.bold())
            SecureField("Password", text: $password).textFieldStyle(.roundedBorder)
            TextField("Key", text: $key).textFieldStyle(.roundedBorder)
            SecureField("Value", text: $value).textFieldStyle(.roundedBorder)
            HStack {
                Button("Guardar") { result = "Guardado" }
                Button("Recuperar") { result = "Recuperado" }
            }
            if !result.isEmpty { Text(result).padding().background(Color(.textBackgroundColor)).cornerRadius(8) }
            Spacer()
        }.padding().frame(maxWidth: 500)
    }
}
