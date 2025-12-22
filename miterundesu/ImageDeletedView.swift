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

    var body: some View {
        ZStack {
            // 背景色
            Color("MainGreen")
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // アイコンとメッセージ
                VStack(spacing: 32) {
                    // タイマーアイコン（ウェルカム画面のロゴと同じサイズ感）
                    Image(systemName: "timer")
                        .font(.system(size: 120, weight: .light))
                        .foregroundColor(.white)
                        .accessibilityHidden(true)

                    // メッセージ
                    VStack(spacing: 16) {
                        Text(settingsManager.localizationManager.localizedString("image_deleted_title"))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(settingsManager.localizationManager.localizedString("image_deleted_reason"))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 40)
                    }
                    .accessibilityElement(children: .combine)
                }

                Spacer()

                // 閉じるボタン（VoiceOver有効時のみ表示）
                if UIAccessibility.isVoiceOverRunning {
                    Button(action: onClose) {
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
            // VoiceOverが無効の場合のみ自動消去
            if !UIAccessibility.isVoiceOverRunning {
                DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                    onClose()
                }
            }
        }
    }
}
