//
//  TutorialWelcomeView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

struct TutorialWelcomeView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // 背景色
            Color("MainGreen")
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // アプリアイコン
                VStack(spacing: 24) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

                    // ようこそメッセージ
                    VStack(spacing: 16) {
                        Text(settingsManager.localizationManager.localizedString("welcome_title"))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(settingsManager.localizationManager.localizedString("welcome_message"))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 40)
                    }
                }

                Spacer()

                // 機能紹介カード
                VStack(spacing: 20) {
                    FeatureCard(
                        icon: "viewfinder.circle.fill",
                        title: settingsManager.localizationManager.localizedString("feature_magnify"),
                        description: settingsManager.localizationManager.localizedString("feature_magnify_desc")
                    )

                    FeatureCard(
                        icon: "eye.slash.fill",
                        title: settingsManager.localizationManager.localizedString("feature_privacy"),
                        description: settingsManager.localizationManager.localizedString("feature_privacy_desc")
                    )

                    FeatureCard(
                        icon: "theatermasks.fill",
                        title: settingsManager.localizationManager.localizedString("feature_theater"),
                        description: settingsManager.localizationManager.localizedString("feature_theater_desc")
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // 始めるボタン
                Button(action: {
                    onboardingManager.completeWelcomeScreen()
                }) {
                    HStack(spacing: 12) {
                        Text(settingsManager.localizationManager.localizedString("get_started"))
                            .font(.system(size: 20, weight: .bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
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
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.15))
        )
    }
}

// MARK: - Preview
struct TutorialWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialWelcomeView(settingsManager: SettingsManager())
    }
}
