import WidgetKit
import SwiftUI

struct MACRONWidget: Widget {
    let kind: String = "MACRONWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MACRONWidgetView(entry: entry)
        }
        .configurationDisplayName("MACRON")
        .description("Estado de MACRON")
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: Date(), status: "Online") }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) { completion(SimpleEntry(date: Date(), status: "Online")) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date(), status: "Online")
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let status: String
}

struct MACRONWidgetView: View {
    var entry: Provider.Entry
    var body: some View {
        VStack {
            Image(systemName: "brain.head.profile").font(.largeTitle).foregroundColor(.orange)
            Text("MACRON").font(.headline)
            Text(entry.status).font(.caption).foregroundColor(.green)
        }
    }
}
