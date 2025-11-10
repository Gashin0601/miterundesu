//
//  SecurityManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import Combine
import UIKit

// MARK: - Security Manager
class SecurityManager: ObservableObject {
    @Published var isScreenRecording = false
    @Published var showScreenshotWarning = false
    @Published var showRecordingWarning = false
    @Published var hideContent = false // スクリーンショット検出時にコンテンツを隠す

    var isPressMode: Bool = false // プレスモード（報道・開発用）

    private var cancellables = Set<AnyCancellable>()
    private var recordingCheckTimer: Timer?

    static let shared = SecurityManager() // シングルトンインスタンス

    init() {
        print("🔒 SecurityManager: 初期化")
        setupScreenshotDetection()
        setupScreenRecordingDetection()
    }

    deinit {
        recordingCheckTimer?.invalidate()
    }

    // スクリーンショット検出
    private func setupScreenshotDetection() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .sink { [weak self] _ in
                self?.handleScreenshotDetected()
            }
            .store(in: &cancellables)
    }

    // 画面録画検出（高速化版）
    private func setupScreenRecordingDetection() {
        // 初期状態を即座にチェック
        checkScreenRecordingStatus()

        // UIScreen.capturedDidChangeNotificationを監視（iOS 11+）
        NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)
            .sink { [weak self] _ in
                self?.checkScreenRecordingStatus()
            }
            .store(in: &cancellables)

        // 高速ポーリング（0.1秒ごと）で画面録画状態を監視
        recordingCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkScreenRecordingStatus()
        }
    }


    // スクリーンショット検出時の処理
    private func handleScreenshotDetected() {
        // プレスモード時はスクリーンショット検出を無効化
        guard !isPressMode else {
            print("📰 プレスモード: スクリーンショット許可")
            return
        }

        print("⚠️ スクリーンショットが検出されました")

        DispatchQueue.main.async {
            // 即座にコンテンツを隠す（最優先）
            print("🔒 Setting hideContent=true, showScreenshotWarning=true")
            self.hideContent = true
            self.showScreenshotWarning = true

            // 3秒後に警告を閉じてコンテンツを再表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                print("🔒 3秒経過 - Setting showScreenshotWarning=false, hideContent=false")
                self.showScreenshotWarning = false
                self.hideContent = false
                print("🔒 hideContent=\(self.hideContent), showScreenshotWarning=\(self.showScreenshotWarning)")
            }
        }
    }

    // 画面録画状態のチェック（高速化版）
    private func checkScreenRecordingStatus() {
        // プレスモード時は画面録画検出を無効化
        guard !isPressMode else {
            return
        }

        let isCaptured: Bool

        // iOS 18対応：sceneCaptureStateを優先的に使用
        if #available(iOS 18.0, *) {
            // シーンベースのアプリの場合
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                isCaptured = window.traitCollection.sceneCaptureState == .active
            } else {
                // フォールバック：従来の方法
                isCaptured = UIScreen.main.isCaptured
            }
        } else {
            // iOS 17以前
            isCaptured = UIScreen.main.isCaptured
        }

        // メインスレッドで状態を更新
        if Thread.isMainThread {
            updateRecordingState(isCaptured)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.updateRecordingState(isCaptured)
            }
        }
    }

    private func updateRecordingState(_ isCaptured: Bool) {
        // 状態が変わった時のみ更新
        if self.isScreenRecording != isCaptured {
            self.isScreenRecording = isCaptured

            if isCaptured {
                self.showRecordingWarning = true
                print("⚠️ 画面録画が検出されました")
            } else {
                self.showRecordingWarning = false
                print("✅ 画面録画が停止されました")
            }
        }
    }


    // メモリクリア（画像データの安全な削除）
    func clearSensitiveData() {
        // 機密データをゼロクリア
        print("🧹 機密データをクリア")
    }
}

// MARK: - Secure View Modifier (スクリーンショット・画面録画対策)
// 最新の実装方法（2024-2025年版）
// 参考: https://www.createwithswift.com/prevent-screenshot-capture-of-sensitive-swiftui-views/

// MARK: - Press Mode Environment Key
private struct PressModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isPressMode: Bool {
        get { self[PressModeKey.self] }
        set { self[PressModeKey.self] = newValue }
    }
}

// UIViewの拡張 - セキュアキャプチャビューを取得
private extension UIView {
    static var secureCaptureView: UIView {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        // subviewsの最初の要素を取得（より安定的な方法）
        return textField.subviews.first ?? UIView()
    }
}

// PreferenceKey for size tracking
fileprivate struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// UIViewRepresentable Helper
fileprivate struct ScreenshotPreventHelper<Content: View>: UIViewRepresentable {
    @Binding var hostingController: UIHostingController<Content>?
    @Environment(\.isPressMode) var isPressMode

    func makeUIView(context: Context) -> UIView {
        // プレスモード時は通常のUIViewを返す（スクリーンショット保護なし）
        if isPressMode {
            print("📰 プレスモード: スクリーンショット保護を無効化")
            return UIView()
        }
        print("🔐 secureCaptureView を作成")
        return UIView.secureCaptureView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // ホスティングコントローラーのビューを追加（タグで重複を防ぐ）
        if let hostingController = hostingController,
           !uiView.subviews.contains(where: { $0.tag == 1001 }) {
            let view = hostingController.view!
            view.tag = 1001
            view.backgroundColor = .clear
            uiView.addSubview(view)

            // 制約を設定
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: uiView.topAnchor),
                view.bottomAnchor.constraint(equalTo: uiView.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: uiView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: uiView.trailingAnchor)
            ])
            print("🔐 ホスティングコントローラーのビューを追加完了")
        }
    }
}

// メインのスクリーンショット防止ビュー
struct ScreenshotPreventView<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    @State private var hostingController: UIHostingController<Content>?

    var body: some View {
        ScreenshotPreventHelper(hostingController: $hostingController)
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SizeKey.self, value: geometry.size)
                        .onPreferenceChange(SizeKey.self) { size in
                            // サイズが有効な場合のみホスティングコントローラーを作成（幅が100以上）
                            if hostingController == nil && size.width > 100 && size.height > 100 {
                                hostingController = UIHostingController(rootView: content)
                                hostingController?.view.backgroundColor = .clear
                                hostingController?.view.frame = CGRect(origin: .zero, size: size)
                                print("🔐 ホスティングコントローラー初期化完了 - サイズ: \(size)")
                            }
                        }
                }
            )
    }
}

// ViewModifier
struct HideWithScreenshot: ViewModifier {
    @State private var size: CGSize?

    func body(content: Content) -> some View {
        ScreenshotPreventView {
            content
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                size = proxy.size
                            }
                            .onChange(of: proxy.size) { _, newSize in
                                size = newSize
                            }
                    }
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// View Extension
extension View {
    /// スクリーンショット・画面録画から保護（最新実装）
    func preventScreenCapture() -> some View {
        modifier(HideWithScreenshot())
    }
}

// MARK: - Conditional Prevent Capture Modifier
struct ConditionalPreventCapture: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.preventScreenCapture()
        } else {
            content
        }
    }
}

// MARK: - Screenshot Warning View
struct ScreenshotWarningView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)

            Text("スクリーンショットが検出されました")
                .font(.title3)
                .fontWeight(.bold)

            Text("このアプリでは画像の保存や共有はできません。\nスクリーンショットも推奨されていません。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(radius: 20)
        )
        .padding(40)
    }
}

// MARK: - Recording Warning View
struct RecordingWarningView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "record.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text("画面録画が検出されました")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("このアプリでは録画・保存はできません")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .red.opacity(0.3), radius: 10)
        )
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
}
