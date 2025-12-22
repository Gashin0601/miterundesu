//
//  ImageDeletedView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

/// 画像が自動削除された時に表示するビュー
struct ImageDeletedView: View {
    @ObservedObject var settingsManager: SettingsManager
    let onClose: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let iconSize = screenWidth * 0.15
            let titleSize = screenWidth * 0.055
            let subtitleSize = screenWidth * 0.04
            let buttonPaddingH = screenWidth * 0.08
            let buttonPaddingV = screenWidth * 0.035
            let cardPadding = screenWidth * 0.08
            let cornerRadius = screenWidth * 0.05

            ZStack {
                // 背景
                Color("MainGreen")
                    .ignoresSafeArea()

                // コンテンツカード
                VStack(spacing: screenWidth * 0.05) {
                    // タイマーアイコン
                    Image(systemName: "timer")
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundColor(.white)
                        .accessibilityHidden(true)

                    // メインメッセージ
                    Text(settingsManager.localizationManager.localizedString("image_deleted_title"))
                        .font(.system(size: titleSize, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // サブメッセージ
                    Text(settingsManager.localizationManager.localizedString("image_deleted_reason"))
                        .font(.system(size: subtitleSize, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Spacer()
                        .frame(height: screenWidth * 0.03)

                    // 閉じるボタン
                    Button(action: onClose) {
                        Text(settingsManager.localizationManager.localizedString("close"))
                            .font(.system(size: subtitleSize, weight: .semibold))
                            .foregroundColor(Color("MainGreen"))
                            .padding(.horizontal, buttonPaddingH)
                            .padding(.vertical, buttonPaddingV)
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius * 0.6)
                                    .fill(Color.white)
                            )
                    }
                    .accessibilityLabel(settingsManager.localizationManager.localizedString("close"))
                    .accessibilityHint(settingsManager.localizationManager.localizedString("close_deleted_image_hint"))
                }
                .padding(cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.black.opacity(0.3))
                )
                .padding(.horizontal, screenWidth * 0.1)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
