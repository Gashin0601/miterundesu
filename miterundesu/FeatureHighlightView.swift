//
//  FeatureHighlightView.swift
//  miterundesu
//
//  Created by Claude Code
//
//  NOTE: このビューはSSCoachMarksパッケージを使用します
//  Xcodeで以下のパッケージを追加してください：
//  https://github.com/SimformSolutionsPvtLtd/SSCoachMarks.git

import SwiftUI
// import SSCoachMarks  // パッケージインストール後にアンコメント

// NOTE: このビューはSSCoachMarksパッケージインストール後に使用可能
// 現在は TemporaryFeatureHighlightView を使用してください
/*
struct FeatureHighlightView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @State private var currentStep: Int = 0

    var body: some View {
        ContentView()
            // SSCoachMarksパッケージインストール後に以下を有効化
            .modifier(CoachMarkView(onCoachMarkFinished: {
                onboardingManager.completeOnboarding()
            }))
            // ステップ1: ズーム操作のハイライト
            .showCoachMark(
                order: 0,
                title: settingsManager.localizationManager.localizedString("tutorial_zoom_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_zoom_desc"),
                highlightViewCornerRadius: 8
            )
            // ステップ2: シアターモードのハイライト
            .showCoachMark(
                order: 1,
                title: settingsManager.localizationManager.localizedString("tutorial_theater_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_theater_desc"),
                highlightViewCornerRadius: 8
            )
            // ステップ3: 設定のハイライト
            .showCoachMark(
                order: 2,
                title: settingsManager.localizationManager.localizedString("tutorial_settings_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_settings_desc"),
                highlightViewCornerRadius: 8
            )
            // ステップ4: メッセージ表示のハイライト
            .showCoachMark(
                order: 3,
                title: settingsManager.localizationManager.localizedString("tutorial_message_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_message_desc"),
                highlightViewCornerRadius: 8
            )
    }
}
*/

// MARK: - 一時的な代替実装（SSCoachMarksインストールまでの暫定）
struct TemporaryFeatureHighlightView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @State private var currentStep: Int = 0

    let tutorials: [(icon: String, title: String, description: String)] = [
        ("magnifyingglass.circle.fill", "tutorial_zoom_title", "tutorial_zoom_desc"),
        ("theatermasks.fill", "tutorial_theater_title", "tutorial_theater_desc"),
        ("gearshape.fill", "tutorial_settings_title", "tutorial_settings_desc"),
        ("text.bubble.fill", "tutorial_message_title", "tutorial_message_desc")
    ]

    var body: some View {
        ZStack {
            // 背景色
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // チュートリアルカード
                VStack(spacing: 24) {
                    Image(systemName: tutorials[currentStep].icon)
                        .font(.system(size: 60))
                        .foregroundColor(Color("MainGreen"))
                        .accessibilityHidden(true)

                    VStack(spacing: 12) {
                        Text(settingsManager.localizationManager.localizedString(tutorials[currentStep].title))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text(settingsManager.localizationManager.localizedString(tutorials[currentStep].description))
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color("MainGreen").opacity(0.95))
                )
                .padding(.horizontal, 32)

                // ステップインジケーター
                HStack(spacing: 8) {
                    ForEach(0..<tutorials.count, id: \.self) { index in
                        Circle()
                            .fill(currentStep == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 16)
                .accessibilityHidden(true)

                // ナビゲーションボタン
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: {
                            currentStep -= 1
                        }) {
                            Text(settingsManager.localizationManager.localizedString("back"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color("MainGreen"))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.white)
                                )
                        }
                        .accessibilityLabel(settingsManager.localizationManager.localizedString("back"))
                    }

                    Spacer()

                    Button(action: {
                        if currentStep < tutorials.count - 1 {
                            currentStep += 1
                        } else {
                            onboardingManager.completeOnboarding()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentStep < tutorials.count - 1 ? settingsManager.localizationManager.localizedString("next") : settingsManager.localizationManager.localizedString("tutorial_complete"))
                                .font(.system(size: 16, weight: .bold))
                            if currentStep < tutorials.count - 1 {
                                Image(systemName: "arrow.right")
                                    .accessibilityHidden(true)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .accessibilityHidden(true)
                            }
                        }
                        .foregroundColor(Color("MainGreen"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white)
                        )
                    }
                    .accessibilityLabel(currentStep < tutorials.count - 1 ? settingsManager.localizationManager.localizedString("next") : settingsManager.localizationManager.localizedString("tutorial_complete"))
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
struct FeatureHighlightView_Previews: PreviewProvider {
    static var previews: some View {
        TemporaryFeatureHighlightView(settingsManager: SettingsManager())
    }
}
