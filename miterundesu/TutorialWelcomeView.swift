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

                // ロゴとアイコン
                VStack(spacing: 32) {
                    // 文字ロゴ
                    Image("LogoTextOnly")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)

                    // アプリアイコン（正方形）
                    Image("miterundesu_app_icon_1024")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .cornerRadius(26)
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)

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

                // 始めるボタン
                VStack(spacing: 16) {
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

                    // スキップボタン（始めるボタンの下）
                    Button(action: {
                        onboardingManager.completeOnboarding()
                    }) {
                        Text(settingsManager.localizationManager.localizedString("skip"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
struct TutorialWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialWelcomeView(settingsManager: SettingsManager())
    }
}
