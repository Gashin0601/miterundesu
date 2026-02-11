//
//  ImageDeletedView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import UIKit

/// 画像が自動削除された時に表示するビュー
struct ImageDeletedView: View {
    @ObservedObject var settingsManager: SettingsManager
    let onClose: () -> Void

    /// 自動消去までの時間（秒）
    private let autoDismissDelay: TimeInterval = 2.5
    /// VoiceOver ON時の自動消去までの時間（読み上げ完了を待つ）
    private let voiceOverDismissDelay: TimeInterval = 3.0
    /// onCloseの二重呼び出し防止
    @State private var hasClosed = false

    var body: some View {
        ZStack {
            // 背景色
            Color("MainGreen")
                .ignoresSafeArea()

            VStack(spacing: 50) {
                Spacer()

                // ゴミ箱アイコン（TutorialCompletionViewと同じサークルパターン）
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(.white)
                        .frame(width: 120, height: 120)

                    Image(systemName: "trash")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(Color("MainGreen"))
                }
                .accessibilityHidden(true)

                // メッセージ
                VStack(spacing: 20) {
                    Text(settingsManager.localizationManager.localizedString("image_deleted_title"))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(settingsManager.localizationManager.localizedString("image_deleted_reason"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                }
                .accessibilityElement(children: .combine)

                Spacer()

                // 閉じるボタン（VoiceOver有効時のみ表示）
                if UIAccessibility.isVoiceOverRunning {
                    Button(action: { closeSafely() }) {
                        HStack(spacing: 12) {
                            Text(settingsManager.localizationManager.localizedString("close"))
                                .font(.system(size: 20, weight: .bold))
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .accessibilityHidden(true)
                        }
                        .foregroundColor(Color("MainGreen"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                    }
                    .accessibilityLabel(settingsManager.localizationManager.localizedString("close"))
                    .accessibilityHint(settingsManager.localizationManager.localizedString("close_deleted_image_hint"))
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // 触覚フィードバック（警告）
            UINotificationFeedbackGenerator().notificationOccurred(.warning)

            if UIAccessibility.isVoiceOverRunning {
                // VoiceOverアナウンス
                let announcement = settingsManager.localizationManager.localizedString("image_deleted_title")
                UIAccessibility.post(notification: .announcement, argument: announcement)

                // 読み上げ完了後に自動消去
                DispatchQueue.main.asyncAfter(deadline: .now() + voiceOverDismissDelay) {
                    closeSafely()
                }
            } else {
                // VoiceOFF: 2.5秒後に自動消去
                DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                    closeSafely()
                }
            }
        }
    }

    /// onCloseを一度だけ呼び出す
    private func closeSafely() {
        guard !hasClosed else { return }
        hasClosed = true
        onClose()
    }
}
