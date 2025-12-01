//
//  WhatsNewView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

/// v1.1.0の新機能案内ビュー
struct WhatsNewView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject private var whatsNewManager = WhatsNewManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // 背景
            Color("MainGreen")
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // タイトル
                VStack(spacing: 10) {
                    Text(settingsManager.localizationManager.localizedString("whats_new_title"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("v1.1.0")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // 新機能リスト
                VStack(alignment: .leading, spacing: 20) {
                    // 新機能1: 1倍ボタンの長押し
                    FeatureRow(
                        icon: "1.circle.fill",
                        title: settingsManager.localizationManager.localizedString("whats_new_feature1_title"),
                        description: settingsManager.localizationManager.localizedString("whats_new_feature1_desc")
                    )
                }
                .padding(.horizontal, 30)

                Spacer()

                // 閉じるボタン
                Button(action: {
                    whatsNewManager.markWhatsNewAsSeen()
                    dismiss()
                }) {
                    Text(settingsManager.localizationManager.localizedString("whats_new_close"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("MainGreen"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}

/// 新機能の行表示
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Preview
#Preview {
    WhatsNewView(settingsManager: SettingsManager())
}
