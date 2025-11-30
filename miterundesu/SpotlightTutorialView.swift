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
    let targetViewIds: [String]  // 複数のビューをハイライト可能に
    let position: SpotlightPosition

    enum SpotlightPosition {
        case above
        case below
        case leading
        case trailing
    }

    // 後方互換性のため、単一のtargetViewIdも受け付ける
    init(id: String, title: String, description: String, targetViewId: String, position: SpotlightPosition) {
        self.id = id
        self.title = title
        self.description = description
        self.targetViewIds = [targetViewId]
        self.position = position
    }

    init(id: String, title: String, description: String, targetViewIds: [String], position: SpotlightPosition) {
        self.id = id
        self.title = title
        self.description = description
        self.targetViewIds = targetViewIds
        self.position = position
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
            .modifier(SpotlightAccessibilityModifier(id: id))
    }
}

// MARK: - Spotlight Accessibility Modifier
/// チュートリアル中、ハイライトされていない要素をVoiceOverから隠す
struct SpotlightAccessibilityModifier: ViewModifier {
    let id: String
    @ObservedObject private var onboardingManager = OnboardingManager.shared

    func body(content: Content) -> some View {
        content
            .accessibilityHidden(
                onboardingManager.showFeatureHighlights && !onboardingManager.currentHighlightedIDs.contains(id)
            )
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

        // チュートリアルステップの定義（5ステップ: ズーム、撮影、シアター、メッセージ、設定）
        self.steps = [
            // Step 1: ズーム操作（+/-/1xボタンと倍率表示）
            SpotlightStep(
                id: "zoom",
                title: settingsManager.localizationManager.localizedString("tutorial_zoom_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_zoom_desc"),
                targetViewIds: ["zoom_buttons", "zoom_controls"],
                position: .above
            ),
            // Step 2: 撮影機能（シャッターボタンと写真ボタン）
            SpotlightStep(
                id: "capture",
                title: settingsManager.localizationManager.localizedString("tutorial_capture_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_capture_desc"),
                targetViewIds: ["shutter_button", "photo_button"],
                position: .above
            ),
            // Step 3: シアターモード
            SpotlightStep(
                id: "theater",
                title: settingsManager.localizationManager.localizedString("tutorial_theater_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_theater_desc"),
                targetViewId: "theater_toggle",
                position: .below
            ),
            // Step 4: メッセージ機能（スクロールメッセージと説明ボタン）
            SpotlightStep(
                id: "message",
                title: settingsManager.localizationManager.localizedString("tutorial_message_title"),
                description: settingsManager.localizationManager.localizedString("tutorial_message_desc"),
                targetViewIds: ["scrolling_message", "explanation_button"],
                position: .below
            ),
            // Step 5: 設定
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
        // 複数のターゲットフレームを取得（IDとフレームのペア）
        let targetData: [(id: String, frame: CGRect)] = currentStep.targetViewIds.compactMap { id in
            if let frame = spotlightFrames[id] {
                return (id, frame)
            }
            return nil
        }

        // デフォルトフレーム（ターゲットが見つからない場合）
        let defaultFrame = CGRect(
            x: geometry.size.width / 2,
            y: geometry.size.height / 2,
            width: 100,
            height: 100
        )

        // フレームリスト（ハイライト用）
        let targetFrames = targetData.map { $0.frame }

        // プライマリターゲット（説明カードの位置計算用）は最初のフレーム
        let primaryTargetFrame = targetFrames.first ?? defaultFrame

        // カードの位置を動的に計算
        let cardCenter = calculateCardCenter(
            geometry: geometry,
            targetFrame: primaryTargetFrame,
            position: currentStep.position
        )

        ZStack {
            // ダークオーバーレイ（複数のハイライト部分を切り抜き）
            SpotlightOverlay(
                highlightFrames: targetFrames.isEmpty ? [defaultFrame] : targetFrames,
                cornerRadius: 12
            )
            .accessibilityHidden(true)

            // 矢印（カードからプライマリターゲットへ1本のみ）
            // ターゲットが見つかった場合のみ表示
            if !targetFrames.isEmpty {
                TutorialArrowView(
                    cardCenter: cardCenter,
                    targetFrame: primaryTargetFrame,
                    position: currentStep.position
                )
                .transition(.opacity)
                .accessibilityHidden(true)
            }

            // 説明カード（動的位置）
            TutorialDescriptionCard(
                step: currentStep,
                targetFrame: primaryTargetFrame,
                geometry: geometry,
                currentIndex: currentStepIndex,
                totalSteps: steps.count,
                onNext: nextStep,
                onPrevious: previousStep,
                onComplete: completeTutorial,
                settingsManager: settingsManager
            )
        }
        .onAppear {
            // 現在のステップのハイライトIDを設定
            onboardingManager.currentHighlightedIDs = Set(currentStep.targetViewIds)
            // VoiceOver: チュートリアル開始時に最初のステップを読み上げ
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                announceCurrentStep()
            }
        }
        .onChange(of: currentStepIndex) { _, _ in
            // ステップ変更時にハイライトIDを更新
            onboardingManager.currentHighlightedIDs = Set(currentStep.targetViewIds)
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
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStepIndex += 1
            }
            // VoiceOver: 次のステップを読み上げ
            announceCurrentStep()
        }
    }

    private func previousStep() {
        if currentStepIndex > 0 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStepIndex -= 1
            }
            // VoiceOver: 前のステップを読み上げ
            announceCurrentStep()
        }
    }

    private func announceCurrentStep() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let step = steps[currentStepIndex]
            let announcement = "\(step.title)。\(step.description)"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    private func completeTutorial() {
        onboardingManager.currentHighlightedIDs = []
        onboardingManager.completeFeatureHighlights()
    }
}

// MARK: - Spotlight Overlay
struct SpotlightOverlay: View {
    let highlightFrames: [CGRect]  // 複数のハイライトをサポート
    let cornerRadius: CGFloat

    var body: some View {
        Canvas { context, size in
            // 全体を暗くする
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.black.opacity(0.7))
            )

            // 複数のハイライト部分を切り抜き
            context.blendMode = .destinationOut
            for highlightFrame in highlightFrames {
                let highlightPath = Path(
                    roundedRect: highlightFrame.insetBy(dx: -8, dy: -8),
                    cornerRadius: cornerRadius
                )
                context.fill(highlightPath, with: .color(.white))
            }
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
        // 矢印パス（破線の直線のみ）
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

    /// カード配置ロジック - ターゲット要素の位置に応じて動的に配置
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
                .id(step.id + "_title")  // コンテンツ変更を識別
                .transition(.opacity)

            // 説明
            Text(step.description)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .id(step.id + "_desc")  // コンテンツ変更を識別
                .transition(.opacity)

            // ステップインジケーター
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 8)
            .accessibilityHidden(true)

            // ナビゲーションボタン
            HStack(spacing: 16) {
                if currentIndex > 0 {
                    Button(action: onPrevious) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .accessibilityHidden(true)
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
                    .accessibilityLabel(settingsManager.localizationManager.localizedString("tutorial_back"))
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
                                .accessibilityHidden(true)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .accessibilityHidden(true)
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
                .accessibilityLabel(currentIndex < totalSteps - 1 ?
                    settingsManager.localizationManager.localizedString("tutorial_next") :
                    settingsManager.localizationManager.localizedString("tutorial_complete"))
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
