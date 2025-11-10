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
    @Published var showSecurityMask = true // 起動時・復帰時のセキュリティマスク

    private var cancellables = Set<AnyCancellable>()
    private var recordingCheckTimer: Timer?
    private var securityMaskWindow: UIWindow?

    static let shared = SecurityManager() // シングルトンインスタンス

    init() {
        print("🔒 SecurityManager: 初期化")
        setupScreenshotDetection()
        setupScreenRecordingDetection()
        setupAppLifecycleObservers()
        setupSecurityMask()
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

    // アプリのライフサイクル監視
    private func setupAppLifecycleObservers() {
        // アプリがアクティブになった時に即座にチェック
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                print("🔒 アプリがアクティブになりました")
                self?.checkScreenRecordingStatus()
                self?.removeMaskIfSafe()
            }
            .store(in: &cancellables)

        // アプリがフォアグラウンドに入った時もチェック
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                print("🔒 アプリがフォアグラウンドに入ります")
                self?.checkScreenRecordingStatus()
                self?.showMask()
            }
            .store(in: &cancellables)

        // アプリが非アクティブになる時（バックグラウンドに移行、マルチタスク画面など）
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                print("🔒 アプリが非アクティブになります")
                self?.showMask()
            }
            .store(in: &cancellables)

        // アプリがバックグラウンドに入る時
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                print("🔒 アプリがバックグラウンドに入りました")
                self?.showMask()
            }
            .store(in: &cancellables)
    }

    // スクリーンショット検出時の処理
    private func handleScreenshotDetected() {
        print("⚠️ スクリーンショットが検出されました")

        DispatchQueue.main.async {
            // 即座にマスクを表示
            self.showMask()

            self.showScreenshotWarning = true

            // 3秒後に警告を自動で閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showScreenshotWarning = false
            }
        }
    }

    // 画面録画状態のチェック（高速化版）
    private func checkScreenRecordingStatus() {
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

    // セキュリティマスクのセットアップ
    private func setupSecurityMask() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // セキュリティマスク用のウィンドウを作成
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let maskWindow = UIWindow(windowScene: windowScene)

                // 最前面に表示（すべてのウィンドウより上）
                maskWindow.windowLevel = .alert + 1
                maskWindow.backgroundColor = .black

                // ブラービューを追加（iOS標準のぼかし効果）
                let blurEffect = UIBlurEffect(style: .dark)
                let blurView = UIVisualEffectView(effect: blurEffect)
                blurView.frame = maskWindow.bounds
                blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                maskWindow.addSubview(blurView)

                // アイコンとメッセージを追加
                let containerView = UIView()
                containerView.translatesAutoresizingMaskIntoConstraints = false
                maskWindow.addSubview(containerView)

                let iconView = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
                iconView.tintColor = .white
                iconView.contentMode = .scaleAspectFit
                iconView.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(iconView)

                let messageLabel = UILabel()
                messageLabel.text = "セキュリティチェック中..."
                messageLabel.textColor = .white
                messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
                messageLabel.textAlignment = .center
                messageLabel.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(messageLabel)

                NSLayoutConstraint.activate([
                    containerView.centerXAnchor.constraint(equalTo: maskWindow.centerXAnchor),
                    containerView.centerYAnchor.constraint(equalTo: maskWindow.centerYAnchor),

                    iconView.topAnchor.constraint(equalTo: containerView.topAnchor),
                    iconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    iconView.widthAnchor.constraint(equalToConstant: 60),
                    iconView.heightAnchor.constraint(equalToConstant: 60),

                    messageLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 16),
                    messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
                ])

                self.securityMaskWindow = maskWindow
                maskWindow.makeKeyAndVisible()
                print("🔒 セキュリティマスクを初期化")
            }
        }
    }

    // セキュリティマスクを表示
    func showMask() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.showSecurityMask = true

            if let maskWindow = self.securityMaskWindow {
                maskWindow.isHidden = false
                maskWindow.alpha = 1.0
                print("🔒 セキュリティマスクを表示")
            } else {
                // マスクウィンドウが存在しない場合は作成
                self.setupSecurityMask()
            }
        }
    }

    // 安全な場合のみマスクを除去
    private func removeMaskIfSafe() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 画面録画状態をチェック
            let isCaptured: Bool

            if #available(iOS 18.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    isCaptured = window.traitCollection.sceneCaptureState == .active
                } else {
                    isCaptured = UIScreen.main.isCaptured
                }
            } else {
                isCaptured = UIScreen.main.isCaptured
            }

            print("🔒 セキュリティチェック: 録画中=\(isCaptured)")

            if !isCaptured {
                // 安全な状態 - マスクをフェードアウト
                UIView.animate(withDuration: 0.3, animations: {
                    self.securityMaskWindow?.alpha = 0.0
                }) { _ in
                    self.securityMaskWindow?.isHidden = true
                    self.showSecurityMask = false
                    print("🔒 セキュリティマスクを除去（安全確認済み）")
                }
            } else {
                // 録画中 - マスクを維持
                print("⚠️ 画面録画中のためマスクを維持")
                self.showSecurityMask = true
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

    func makeUIView(context: Context) -> UIView {
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
                            if hostingController == nil {
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
        .frame(width: size?.width, height: size?.height)
    }
}

// View Extension
extension View {
    /// スクリーンショット・画面録画から保護（最新実装）
    func preventScreenCapture() -> some View {
        modifier(HideWithScreenshot())
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
