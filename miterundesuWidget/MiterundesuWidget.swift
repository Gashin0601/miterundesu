import WidgetKit
import SwiftUI

struct MiterundesuWidgetEntry: TimelineEntry {
    let date: Date
}

struct MiterundesuWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MiterundesuWidgetEntry {
        MiterundesuWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (MiterundesuWidgetEntry) -> Void) {
        completion(MiterundesuWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MiterundesuWidgetEntry>) -> Void) {
        completion(Timeline(entries: [MiterundesuWidgetEntry(date: Date())], policy: .never))
    }
}

struct MiterundesuWidgetEntryView: View {
    var entry: MiterundesuWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image("WidgetIcon")
                .resizable()
                .scaledToFit()
                .padding(12)
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "miterundesu://open"))
    }
}

struct MiterundesuWidget: Widget {
    let kind = "MiterundesuWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MiterundesuWidgetProvider()) { entry in
            MiterundesuWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ミテルンデス")
        .description("アプリを素早く起動")
        .supportedFamilies([.accessoryCircular])
    }
}
