//
//  TutorialCompletionView.swift
//  miterundesu
//
//  Created by Claude Code
//
//  チュートリアル完了画面

import SwiftUI

struct TutorialCompletionView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var onboardingManager = OnboardingManager.shared

    var body: some View {
        ZStack {
            // 背景色
            Color("MainGreen")
                .ignoresSafeArea()

            VStack(spacing: 50) {
                Spacer()

                // チェックマークアイコン（アニメーション付き）
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(.white)
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(Color("MainGreen"))
                }
                .accessibilityHidden(true)

                // お疲れ様メッセージ
                VStack(spacing: 20) {
                    Text(settingsManager.localizationManager.localizedString("tutorial_completion_title"))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(settingsManager.localizationManager.localizedString("tutorial_completion_message"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // 始めるボタン
                Button(action: {
                    onboardingManager.completeOnboarding()
                }) {
                    HStack(spacing: 12) {
                        Text(settingsManager.localizationManager.localizedString("start_using"))
                            .font(.system(size: 20, weight: .bold))
                        Image(systemName: "arrow.right.circle.fill")
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
                .accessibilityLabel(settingsManager.localizationManager.localizedString("start_using"))
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
struct TutorialCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialCompletionView(settingsManager: SettingsManager())
    }
}
