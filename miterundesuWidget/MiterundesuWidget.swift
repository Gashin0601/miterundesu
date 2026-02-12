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

/// ミテルンデスの目のアイコンをSwiftUI Pathで直接描画
struct EyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // 外側の円（眼球）
        path.move(to: CGPoint(x: 0.5006 * w, y: 0.0025 * h))
        path.addCurve(
            to: CGPoint(x: 1.0004 * w, y: 0.5023 * h),
            control1: CGPoint(x: 0.7766 * w, y: 0.0025 * h),
            control2: CGPoint(x: 1.0004 * w, y: 0.2263 * h)
        )
        path.addCurve(
            to: CGPoint(x: 0.5006 * w, y: 1.0021 * h),
            control1: CGPoint(x: 1.0004 * w, y: 0.7783 * h),
            control2: CGPoint(x: 0.7766 * w, y: 1.0021 * h)
        )
        path.addCurve(
            to: CGPoint(x: 0.0008 * w, y: 0.5023 * h),
            control1: CGPoint(x: 0.2246 * w, y: 1.0021 * h),
            control2: CGPoint(x: 0.0008 * w, y: 0.7783 * h)
        )
        path.addCurve(
            to: CGPoint(x: 0.5006 * w, y: 0.0025 * h),
            control1: CGPoint(x: 0.0008 * w, y: 0.2263 * h),
            control2: CGPoint(x: 0.2246 * w, y: 0.0025 * h)
        )
        path.closeSubpath()

        // 内側の円（瞳孔）- くり抜き用
        path.move(to: CGPoint(x: 0.3319 * w, y: 0.1406 * h))
        path.addCurve(
            to: CGPoint(x: 0.1112 * w, y: 0.3613 * h),
            control1: CGPoint(x: 0.2100 * w, y: 0.1406 * h),
            control2: CGPoint(x: 0.1112 * w, y: 0.2394 * h)
        )
        path.addCurve(
            to: CGPoint(x: 0.3319 * w, y: 0.5819 * h),
            control1: CGPoint(x: 0.1112 * w, y: 0.4831 * h),
            control2: CGPoint(x: 0.2100 * w, y: 0.5819 * h)
        )
        path.addCurve(
            to: CGPoint(x: 0.5525 * w, y: 0.3613 * h),
            control1: CGPoint(x: 0.4537 * w, y: 0.5819 * h),
            control2: CGPoint(x: 0.5525 * w, y: 0.4831 * h)
        )
        path.addCurve(
            to: CGPoint(x: 0.3319 * w, y: 0.1406 * h),
            control1: CGPoint(x: 0.5525 * w, y: 0.2394 * h),
            control2: CGPoint(x: 0.4537 * w, y: 0.1406 * h)
        )
        path.closeSubpath()

        return path
    }
}

struct MiterundesuWidgetEntryView: View {
    var entry: MiterundesuWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            EyeShape()
                .fill(.white)
                .padding(10)
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
