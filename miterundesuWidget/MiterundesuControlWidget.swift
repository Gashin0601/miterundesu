import WidgetKit
import SwiftUI

@available(iOS 18.0, *)
struct MiterundesuControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "jp-mieruwa.miterundesu.LaunchControl") {
            ControlWidgetButton(action: LaunchMiterundesuIntent()) {
                Label("ミテルンデス", systemImage: "eye")
            }
        }
        .displayName("ミテルンデスを開く")
        .description("拡大鏡アプリを起動")
    }
}
