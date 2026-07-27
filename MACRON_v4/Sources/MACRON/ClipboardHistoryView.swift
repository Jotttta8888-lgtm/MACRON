import SwiftUI

struct ClipboardHistoryView: View {
    @StateObject private var service = ClipboardHistoryService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "doc.on.clipboard").foregroundColor(.accentColor)
                Text("Historial del Portapapeles").font(.headline)
                Spacer()
                Button(action: { service.clear() }) {
                    Image(systemName: "trash").foregroundColor(.red)
                }.buttonStyle(.plain)
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }.buttonStyle(.plain)
            }.padding()
            
            if service.items.isEmpty {
                Spacer()
                Text("Vacío").foregroundColor(.secondary)
                Spacer()
            } else {
                List(service.items) { item in
                    HStack {
                        Text(item.text).lineLimit(2).font(.system(size: 13))
                        Spacer()
                        Text(item.timestamp, style: .time).font(.caption2).foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        service.copyToClipboard(item)
                        dismiss()
                    }
                }.listStyle(.plain)
            }
        }.frame(width: 400, height: 500)
    }
}
