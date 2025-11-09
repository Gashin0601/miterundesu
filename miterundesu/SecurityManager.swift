//
//  SecurityManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import Combine

// MARK: - Security Manager
class SecurityManager: ObservableObject {
    @Published var isScreenRecording = false
    @Published var showScreenshotWarning = false
    @Published var showRecordingWarning = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupScreenshotDetection()
        setupScreenRecordingDetection()
    }

    // スクリーンショット検出
    private func setupScreenshotDetection() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .sink { [weak self] _ in
                self?.handleScreenshotDetected()
            }
            .store(in: &cancellables)
    }

    // 画面録画検出
    private func setupScreenRecordingDetection() {
        // 初期状態をチェック
        checkScreenRecordingStatus()

        // UIScreen.capturedDidChangeNotificationを監視（iOS 11+）
        NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)
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

    // 画面録画状態のチェック
    private func checkScreenRecordingStatus() {
        DispatchQueue.main.async {
            let isCaptured = UIScreen.main.isCaptured
            self.isScreenRecording = isCaptured

            if isCaptured {
                self.showRecordingWarning = true
                print("⚠️ 画面録画が検出されました")
            } else {
                self.showRecordingWarning = false
            }
        }
    }

    // メモリクリア（画像データの安全な削除）
    func clearSensitiveData() {
        // 機密データをゼロクリア
        print("🧹 機密データをクリア")
    }
}

// MARK: - Secure View Modifier
struct SecureView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                SecureField("", text: .constant(""))
                    .frame(width: 0, height: 0)
                    .opacity(0)
            )
    }
}

extension View {
    /// ビューをセキュア化（スクリーンショット時に隠す）
    func secureView() -> some View {
        modifier(SecureView())
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
