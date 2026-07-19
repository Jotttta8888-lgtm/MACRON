import SwiftUI
struct PlansView: View {
    @ObservedObject var orchestrator: MacronOrchestrator
    @State private var title = "", description = "", steps = ""
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Nuevo Plan").font(.title3.bold())
                TextField("Titulo", text: $title).textFieldStyle(.roundedBorder)
                TextField("Descripcion", text: $description).textFieldStyle(.roundedBorder)
                TextField("Pasos (sep. por coma)", text: $steps).textFieldStyle(.roundedBorder)
                Button("Crear") { }.buttonStyle(.borderedProminent)
                Spacer()
            }.frame(width: 300).padding()
            Divider()
            VStack(alignment: .leading) {
                Text("Planes").font(.title3.bold())
                Spacer()
            }.padding()
        }
    }
}
