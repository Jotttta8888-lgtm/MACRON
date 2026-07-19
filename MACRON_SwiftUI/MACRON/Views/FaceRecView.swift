import SwiftUI
struct FaceRecView: View {
    @ObservedObject var orchestrator: MacronOrchestrator
    @State private var name = ""
    var body: some View {
        VStack(spacing: 20) {
            Text("Face Recognition").font(.title2.bold())
            Image(systemName: "faceid").font(.system(size: 60)).foregroundColor(.accentColor)
            Text(orchestrator.modules.faceRec ? "dlib activo" : "dlib no instalado")
                .foregroundColor(orchestrator.modules.faceRec ? .green : .red)
            TextField("Nombre", text: $name).textFieldStyle(.roundedBorder).frame(maxWidth: 300)
            Button("Registrar") { }.buttonStyle(.borderedProminent)
            Spacer()
        }.padding()
    }
}
