import WidgetKit
import SwiftUI

@main
struct MiterundesuWidgetBundle: WidgetBundle {
    var body: some Widget {
        MiterundesuWidget()
        if #available(iOSApplicationExtension 18.0, *) {
            MiterundesuControlWidget()
        }
    }
}
