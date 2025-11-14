//
//  SpotlightTutorialView.swift
//  miterundesu
//
//  Created by Claude Code
//
//  UI要素を直接ハイライトするチュートリアルシステム

import SwiftUI

// MARK: - Spotlight Tutorial Step
struct SpotlightStep: Identifiable {
    let id: String
    let title: String
    let description: String
    let targetViewId: String
    let position: SpotlightPosition

    enum SpotlightPosition {
        case above
        case below
        case leading
        case trailing
    }
}

// MARK: - Spotlight Preference Key
struct SpotlightPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - Spotlight Modifier
struct SpotlightModifier: ViewModifier {
    let id: String

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: SpotlightPreferenceKey.self,
                            value: [id: geometry.frame(in: .global)]
                        )
                }
            )
    }
}

extension View {
    func spotlight(id: String) -> some View {
        modifier(SpotlightModifier(id: id))
    }
}

// MARK: - Spotlight Tutorial View
struct SpotlightTutorialView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @State private var currentStepIndex: Int = 0
    @State private var spotlightFrames: [String: CGRect] = [:]

    let steps: [SpotlightStep]

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager

        // チュートリアルステップの定義
        self.steps = [
            SpotlightStep(
                id: "zoom",
                title: settingsManager.localizationManager.localizedString("tutorial_zoom_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_zoom_desc"),
                targetViewId: "zoom_controls",
                position: .above
            ),
            SpotlightStep(
                id: "theater",
                title: settingsManager.localizationManager.localizedString("tutorial_theater_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_theater_desc"),
                targetViewId: "theater_toggle",
                position: .below
            ),
            SpotlightStep(
                id: "settings",
                title: settingsManager.localizationManager.localizedString("tutorial_settings_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_settings_desc"),
                targetViewId: "settings_button",
                position: .below
            ),
            SpotlightStep(
                id: "message",
                title: settingsManager.localizationManager.localizedString("tutorial_message_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_message_desc"),
                targetViewId: "scrolling_message",
                position: .below
            )
        ]
    }

    var currentStep: SpotlightStep {
        steps[currentStepIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // ダークオーバーレイ（ハイライト部分を切り抜き）
                SpotlightOverlay(
                    highlightFrame: spotlightFrames[currentStep.targetViewId] ?? .zero,
                    cornerRadius: 12
                )
                .animation(.easeInOut(duration: 0.3), value: currentStep.targetViewId)

                // 説明カード
                if let targetFrame = spotlightFrames[currentStep.targetViewId] {
                    TutorialDescriptionCard(
                        step: currentStep,
                        targetFrame: targetFrame,
                        geometry: geometry,
                        currentIndex: currentStepIndex,
                        totalSteps: steps.count,
                        onNext: nextStep,
                        onPrevious: previousStep,
                        onComplete: completeTutorial
                    )
                }
            }
            .onPreferenceChange(SpotlightPreferenceKey.self) { preferences in
                spotlightFrames = preferences
            }
        }
        .ignoresSafeArea()
    }

    private func nextStep() {
        if currentStepIndex < steps.count - 1 {
            withAnimation {
                currentStepIndex += 1
            }
        }
    }

    private func previousStep() {
        if currentStepIndex > 0 {
            withAnimation {
                currentStepIndex -= 1
            }
        }
    }

    private func completeTutorial() {
        onboardingManager.completeOnboarding()
    }
}

// MARK: - Spotlight Overlay
struct SpotlightOverlay: View {
    let highlightFrame: CGRect
    let cornerRadius: CGFloat

    var body: some View {
        Canvas { context, size in
            // 全体を暗くする
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.black.opacity(0.7))
            )

            // ハイライト部分を切り抜き
            let highlightPath = Path(
                roundedRect: highlightFrame.insetBy(dx: -8, dy: -8),
                cornerRadius: cornerRadius
            )

            context.blendMode = .destinationOut
            context.fill(highlightPath, with: .color(.white))
        }
    }
}

// MARK: - Tutorial Description Card
struct TutorialDescriptionCard: View {
    let step: SpotlightStep
    let targetFrame: CGRect
    let geometry: GeometryProxy
    let currentIndex: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onComplete: () -> Void

    private var cardOffset: CGPoint {
        let screenHeight = geometry.size.height
        let screenWidth = geometry.size.width

        switch step.position {
        case .above:
            // ターゲットの上に配置
            return CGPoint(
                x: (screenWidth - 300) / 2,
                y: max(20, targetFrame.minY - 180)
            )
        case .below:
            // ターゲットの下に配置
            return CGPoint(
                x: (screenWidth - 300) / 2,
                y: min(screenHeight - 200, targetFrame.maxY + 20)
            )
        case .leading:
            return CGPoint(x: 20, y: targetFrame.midY - 75)
        case .trailing:
            return CGPoint(x: screenWidth - 320, y: targetFrame.midY - 75)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // タイトル
            Text(step.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // 説明
            Text(step.description)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // ステップインジケーター
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 8)

            // ナビゲーションボタン
            HStack(spacing: 16) {
                if currentIndex > 0 {
                    Button(action: onPrevious) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("戻る")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color("MainGreen"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                        )
                    }
                }

                Spacer()

                Button(action: {
                    if currentIndex < totalSteps - 1 {
                        onNext()
                    } else {
                        onComplete()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(currentIndex < totalSteps - 1 ? "次へ" : "完了")
                        if currentIndex < totalSteps - 1 {
                            Image(systemName: "chevron.right")
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color("MainGreen"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white)
                    )
                }
            }
        }
        .padding(20)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("MainGreen"))
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
        )
        .position(cardOffset)
    }
}

// MARK: - Preview
struct SpotlightTutorialView_Previews: PreviewProvider {
    static var previews: some View {
        SpotlightTutorialView(settingsManager: SettingsManager())
    }
}
