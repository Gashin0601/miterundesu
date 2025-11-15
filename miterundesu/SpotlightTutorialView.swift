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
    let spotlightFrames: [String: CGRect]

    let steps: [SpotlightStep]

    init(settingsManager: SettingsManager, spotlightFrames: [String: CGRect]) {
        self.settingsManager = settingsManager
        self.spotlightFrames = spotlightFrames

        // チュートリアルステップの定義（3ステップ: ズーム、シアターモード、設定）
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
            )
        ]
    }

    var currentStep: SpotlightStep {
        steps[currentStepIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            tutorialContent(geometry: geometry)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func tutorialContent(geometry: GeometryProxy) -> some View {
        let targetFrame = spotlightFrames[currentStep.targetViewId] ?? CGRect(
            x: geometry.size.width / 2,
            y: geometry.size.height / 2,
            width: 100,
            height: 100
        )
        let cardCenter = calculateCardCenter(
            geometry: geometry,
            targetFrame: targetFrame,
            position: currentStep.position
        )

        ZStack {
            // ダークオーバーレイ（ハイライト部分を切り抜き）
            SpotlightOverlay(
                highlightFrame: targetFrame,
                cornerRadius: 12
            )
            .animation(.easeInOut(duration: 0.3), value: currentStep.targetViewId)

            // 矢印（カードとターゲット要素を結ぶ）- UIと被らないようにエッジまで伸ばす
            TutorialArrowView(
                cardCenter: cardCenter,
                targetFrame: targetFrame,
                position: currentStep.position
            )
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: currentStep.targetViewId)

            // 説明カード（常に表示）
            TutorialDescriptionCard(
                step: currentStep,
                targetFrame: targetFrame,
                geometry: geometry,
                currentIndex: currentStepIndex,
                totalSteps: steps.count,
                onNext: nextStep,
                onPrevious: previousStep,
                onComplete: completeTutorial,
                settingsManager: settingsManager
            )
        }
    }

    private func calculateCardCenter(geometry: GeometryProxy, targetFrame: CGRect, position: SpotlightStep.SpotlightPosition) -> CGPoint {
        let cardCenterY: CGFloat
        switch position {
        case .above:
            cardCenterY = max(130, targetFrame.minY - 150)
        case .below:
            cardCenterY = min(geometry.size.height - 130, targetFrame.maxY + 150)
        case .leading, .trailing:
            cardCenterY = targetFrame.midY
        }
        return CGPoint(x: geometry.size.width / 2, y: cardCenterY)
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

// MARK: - Tutorial Arrow
/// カードとターゲット要素を結ぶ矢印コンポーネント
struct TutorialArrowView: View {
    let cardCenter: CGPoint
    let targetFrame: CGRect
    let position: SpotlightStep.SpotlightPosition

    /// カードのエッジから矢印を開始する位置を計算
    private var arrowStartPoint: CGPoint {
        let cardWidth: CGFloat = 150  // カード半幅の概算
        let cardHeight: CGFloat = 110  // カード半高の概算

        switch position {
        case .above:
            // カードの下端中央から開始
            return CGPoint(x: cardCenter.x, y: cardCenter.y + cardHeight)
        case .below:
            // カードの上端中央から開始
            return CGPoint(x: cardCenter.x, y: cardCenter.y - cardHeight)
        case .leading:
            // カードの右端中央から開始
            return CGPoint(x: cardCenter.x + cardWidth, y: cardCenter.y)
        case .trailing:
            // カードの左端中央から開始
            return CGPoint(x: cardCenter.x - cardWidth, y: cardCenter.y)
        }
    }

    /// 矢印の終点（ターゲット要素のエッジ）を計算 - UIと被らないように
    private var arrowEndPoint: CGPoint {
        switch position {
        case .above:
            // カードが上にある → 矢印は下に向かう → ターゲットの上端（minY）まで
            return CGPoint(x: targetFrame.midX, y: targetFrame.minY - 8)
        case .below:
            // カードが下にある → 矢印は上に向かう → ターゲットの下端（maxY）まで
            return CGPoint(x: targetFrame.midX, y: targetFrame.maxY + 8)
        case .leading:
            // カードが左にある → 矢印は右に向かう → ターゲットの左端（minX）まで
            return CGPoint(x: targetFrame.minX - 8, y: targetFrame.midY)
        case .trailing:
            // カードが右にある → 矢印は左に向かう → ターゲットの右端（maxX）まで
            return CGPoint(x: targetFrame.maxX + 8, y: targetFrame.midY)
        }
    }

    /// 矢印ヘッドの角度を計算
    private var arrowAngle: Angle {
        let dx = arrowEndPoint.x - arrowStartPoint.x
        let dy = arrowEndPoint.y - arrowStartPoint.y
        return Angle(radians: atan2(dy, dx))
    }

    var body: some View {
        ZStack {
            // 矢印パス（破線の直線）
            Path { path in
                path.move(to: arrowStartPoint)
                path.addLine(to: arrowEndPoint)
            }
            .stroke(Color.white, style: StrokeStyle(
                lineWidth: 3,
                lineCap: .round,
                dash: [8, 4]
            ))
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

            // 矢印ヘッド（三角形）
            ArrowHead(at: arrowEndPoint, angle: arrowAngle)
        }
    }
}

/// 矢印の先端（三角形）
struct ArrowHead: View {
    let at: CGPoint
    let angle: Angle

    var body: some View {
        Path { path in
            // 三角形のサイズ
            let size: CGFloat = 12

            // 三角形の頂点（先端）
            path.move(to: CGPoint(x: size, y: 0))
            // 底辺の2点
            path.addLine(to: CGPoint(x: -size / 2, y: -size / 2))
            path.addLine(to: CGPoint(x: -size / 2, y: size / 2))
            path.closeSubpath()
        }
        .fill(Color.white)
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        .rotationEffect(angle)
        .position(at)
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
    let settingsManager: SettingsManager

    // カードのサイズ定数
    private let cardWidth: CGFloat = 300
    private let cardHeight: CGFloat = 220  // 概算（実際の高さは内容によって変動）
    private let edgePadding: CGFloat = 20
    private let arrowSpace: CGFloat = 40

    /// 改良されたカード配置ロジック - 画面境界を考慮し、はみ出しや重なりを防ぐ
    private var cardOffset: CGPoint {
        let screenHeight = geometry.size.height
        let screenWidth = geometry.size.width

        // 理想的な配置位置を計算
        var idealPosition: CGPoint

        switch step.position {
        case .above:
            // ターゲットの上に配置（矢印スペース込み）
            idealPosition = CGPoint(
                x: (screenWidth - cardWidth) / 2,
                y: targetFrame.minY - cardHeight - arrowSpace
            )
        case .below:
            // ターゲットの下に配置（矢印スペース込み）
            idealPosition = CGPoint(
                x: (screenWidth - cardWidth) / 2,
                y: targetFrame.maxY + arrowSpace
            )
        case .leading:
            // ターゲットの左に配置
            idealPosition = CGPoint(
                x: targetFrame.minX - cardWidth - arrowSpace,
                y: targetFrame.midY - cardHeight / 2
            )
        case .trailing:
            // ターゲットの右に配置
            idealPosition = CGPoint(
                x: targetFrame.maxX + arrowSpace,
                y: targetFrame.midY - cardHeight / 2
            )
        }

        // 画面境界内に収まるように調整（.position() は中心座標なので cardWidth/2 を考慮）
        let minX = edgePadding + cardWidth / 2
        let maxX = screenWidth - edgePadding - cardWidth / 2
        let minY = edgePadding + cardHeight / 2
        let maxY = screenHeight - edgePadding - cardHeight / 2

        let adjustedX = clamp(idealPosition.x + cardWidth / 2, min: minX, max: maxX)
        let adjustedY = clamp(idealPosition.y + cardHeight / 2, min: minY, max: maxY)

        return CGPoint(x: adjustedX, y: adjustedY)
    }

    /// 値を指定範囲内にクランプする
    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        return Swift.min(Swift.max(value, minValue), maxValue)
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
                            Text(settingsManager.localizationManager.localizedString("tutorial_back"))
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
                        Text(currentIndex < totalSteps - 1 ?
                            settingsManager.localizationManager.localizedString("tutorial_next") :
                            settingsManager.localizationManager.localizedString("tutorial_complete"))
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
        SpotlightTutorialView(
            settingsManager: SettingsManager(),
            spotlightFrames: [:]
        )
    }
}
