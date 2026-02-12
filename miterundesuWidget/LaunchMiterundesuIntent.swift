import AppIntents

@available(iOS 18.0, *)
struct LaunchMiterundesuIntent: AppIntent {
    static var title: LocalizedStringResource = "ミテルンデスを開く"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
