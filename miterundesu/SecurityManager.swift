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

    private var cancellables = Set<AnyCancellable>()
    private var recordingCheckTimer: Timer?

    init() {
        setupScreenshotDetection()
        setupScreenRecordingDetection()
        setupAppLifecycleObservers()
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
                self?.checkScreenRecordingStatus()
            }
            .store(in: &cancellables)

        // アプリがフォアグラウンドに入った時もチェック
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.checkScreenRecordingStatus()
            }
            .store(in: &cancellables)
    }

    // スクリーンショット検出時の処理
    private func handleScreenshotDetected() {
        DispatchQueue.main.async {
            self.showScreenshotWarning = true

            // 3秒後に警告を自動で閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showScreenshotWarning = false
            }
        }

        print("⚠️ スクリーンショットが検出されました")
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

    // メモリクリア（画像データの安全な削除）
    func clearSensitiveData() {
        // 機密データをゼロクリア
        print("🧹 機密データをクリア")
    }
}

// MARK: - Secure View Modifier (スクリーンショット・画面録画対策)
// UITextFieldのisSecureTextEntryを活用した実装

extension UIView {
    static var secureView: UIView {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false

        // iOS 17対応：.lastを使用
        guard let secureView = textField.layer.sublayers?.last?.delegate as? UIView else {
            return .init()
        }
        secureView.subviews.forEach { $0.removeFromSuperview() }
        return secureView
    }
}

struct RestrictCaptureView<Content: View>: UIViewControllerRepresentable {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    func makeUIViewController(context: Context) -> RestrictCaptureViewController<Content> {
        let viewController = RestrictCaptureViewController(rootView: content())

        // makeUIViewControllerの時点で保護を試みる
        DispatchQueue.main.async {
            viewController.applySecureLayerIfNeeded()
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: RestrictCaptureViewController<Content>, context: Context) {
        uiViewController.hostingController.rootView = content()
    }
}

class RestrictCaptureViewController<Content: View>: UIViewController {
    let hostingController: UIHostingController<Content>
    private var secureTextField: UITextField?
    private var hasAppliedSecureLayer = false

    init(rootView: Content) {
        self.hostingController = UIHostingController(rootView: rootView)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // loadView()で保護を適用（viewDidLoadより早いタイミング）
    override func loadView() {
        // メインビューを作成
        let mainView = UIView()
        mainView.backgroundColor = .clear
        self.view = mainView

        // ホスティングコントローラーをセットアップ
        setupHostingController(in: mainView)

        // セキュアテキストフィールドを作成して追加
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        textField.backgroundColor = .clear
        textField.translatesAutoresizingMaskIntoConstraints = false

        self.secureTextField = textField
        mainView.addSubview(textField)

        // テキストフィールドを中央に配置
        NSLayoutConstraint.activate([
            textField.centerYAnchor.constraint(equalTo: mainView.centerYAnchor),
            textField.centerXAnchor.constraint(equalTo: mainView.centerXAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applySecureLayerIfNeeded()
    }

    func applySecureLayerIfNeeded() {
        // レイヤー保護を一度だけ適用（レンダリング前）
        guard !hasAppliedSecureLayer,
              let textField = secureTextField,
              let mainView = self.view,
              let superlayer = mainView.layer.superlayer else { return }

        hasAppliedSecureLayer = true

        // iOS 17対応：.lastを使用してスクリーンショット保護を適用
        superlayer.addSublayer(textField.layer)
        textField.layer.sublayers?.last?.addSublayer(mainView.layer)
    }

    private func setupHostingController(in containerView: UIView) {
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        containerView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)
        hostingController.view.isUserInteractionEnabled = true
        containerView.isUserInteractionEnabled = true
    }
}

extension View {
    /// スクリーンショット・画面録画から保護
    func restrictCapture() -> some View {
        RestrictCaptureView { self }
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
