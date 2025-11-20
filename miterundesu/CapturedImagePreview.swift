//
//  CapturedImagePreview.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

// 撮影直後のプレビュー画面（シャッター位置にバツボタン）
struct CapturedImagePreview: View {
    @ObservedObject var imageManager: ImageManager
    @ObservedObject var settingsManager: SettingsManager
    let capturedImage: CapturedImage
    @Environment(\.dismiss) var dismiss
    @Environment(\.isPressMode) var isPressMode
    @ObservedObject private var securityManager = SecurityManager.shared

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var remainingTime: TimeInterval
    @State private var zoomTimer: Timer?
    @State private var zoomStartTime: Date?
    @State private var continuousZoomCount: Int = 0
    @State private var showSettings = false
    @State private var showExplanation = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(imageManager: ImageManager, settingsManager: SettingsManager, capturedImage: CapturedImage) {
        self.imageManager = imageManager
        self.settingsManager = settingsManager
        self.capturedImage = capturedImage
        _remainingTime = State(initialValue: capturedImage.remainingTime)
    }

    var body: some View {
        GeometryReader { mainGeometry in
            let screenWidth = mainGeometry.size.width
            let screenHeight = mainGeometry.size.height

            // レスポンシブなサイズとパディング値を計算
            let horizontalPadding = screenWidth * 0.05  // 画面幅の5%
            let verticalPadding = screenHeight * 0.01   // 画面高さの1%
            let buttonSize = screenWidth * 0.11         // 画面幅の11%
            let closeButtonSize = screenWidth * 0.18    // 画面幅の18%
            let warningPadding = screenWidth * 0.1      // 画面幅の10%

            ZStack {
                // 緑の背景（全画面）
                Color("MainGreen")
                    .ignoresSafeArea()

            // 画像表示エリア
            ZStack {
                if securityManager.hideContent {
                    // スクリーンショット検出時：完全に黒画面
                    Color.black
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 保護された画像表示
                    ZStack {
                        GeometryReader { geometry in
                        Image(uiImage: capturedImage.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .scaleEffect(scale)
                            .offset(offset)
                            .clipped()
                            .highPriorityGesture(
                                MagnificationGesture(minimumScaleDelta: 0)
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        let newScale = min(max(scale * delta, 1), CGFloat(settingsManager.maxZoomFactor))
                                        scale = newScale
                                        // スケール変更時にオフセットを境界内に制限
                                        offset = boundedOffset(offset, scale: newScale, imageSize: capturedImage.image.size, viewSize: geometry.size)
                                        lastOffset = offset
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture(minimumDistance: scale > 1.0 ? 0 : 10)
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            let newOffset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                            // ドラッグ時にオフセットを境界内に制限
                                            offset = boundedOffset(newOffset, scale: scale, imageSize: capturedImage.image.size, viewSize: geometry.size)
                                        }
                                    }
                                    .onEnded { _ in
                                        if scale > 1.0 {
                                            lastOffset = offset
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                            .onChange(of: scale) { oldValue, newValue in
                                if newValue <= 1.0 {
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    // スケール変更時にオフセットを境界内に調整
                                    offset = boundedOffset(offset, scale: newValue, imageSize: capturedImage.image.size, viewSize: geometry.size)
                                    lastOffset = offset
                                }
                            }
                    }
                    .blur(radius: securityManager.isScreenRecording ? 50 : 0)
                    }
                    .modifier(ConditionalPreventCapture(isEnabled: !isPressMode))
                }

                // 画面録画中の警告（中央）
                if securityManager.isScreenRecording {
                    VStack(spacing: 20) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)

                        Text(settingsManager.localizationManager.localizedString("screen_recording_warning"))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(settingsManager.localizationManager.localizedString("no_recording_message"))
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(warningPadding)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.8))
                    )
                    .accessibilityElement(children: .combine)
                }
            }

            // 左下：ウォーターマークオーバーレイ（常に表示・画像の外側）
            VStack {
                Spacer()
                HStack {
                    WatermarkView(isDarkBackground: true)
                        .padding(.leading, horizontalPadding * 0.6)
                        .padding(.bottom, verticalPadding * 1.2)
                    Spacer()
                }
            }
            .allowsHitTesting(false)

            // 右下：ズームコントロールと倍率表示（画像の外側）
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: buttonSize * 0.18) {
                        // ズームコントロールボタン
                        VStack(spacing: buttonSize * 0.27) {
                        // ズームイン
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: buttonSize, height: buttonSize)

                            Image(systemName: "plus")
                                .font(.system(size: buttonSize * 0.45, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .onTapGesture {
                            zoomIn()
                        }
                        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                            if pressing {
                                startContinuousZoom(direction: .in)
                            } else {
                                stopContinuousZoom()
                            }
                        }, perform: {})
                        .accessibilityLabel("ズームイン")
                        .accessibilityHint("タップで1.5倍拡大、長押しで連続拡大します")

                        // ズームアウト
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: buttonSize, height: buttonSize)

                            Image(systemName: "minus")
                                .font(.system(size: buttonSize * 0.45, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .onTapGesture {
                            zoomOut()
                        }
                        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                            if pressing {
                                startContinuousZoom(direction: .out)
                            } else {
                                stopContinuousZoom()
                            }
                        }, perform: {})
                        .accessibilityLabel("ズームアウト")
                        .accessibilityHint("タップで縮小、長押しで連続縮小します")

                        // リセットボタン（1.circleアイコン）
                        Button(action: {
                            stopContinuousZoom()
                            withAnimation {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: buttonSize, height: buttonSize)

                                Image(systemName: "1.circle")
                                    .font(.system(size: buttonSize * 0.45, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .accessibilityLabel("ズームリセット")
                        .accessibilityHint("画像の拡大を元に戻します")
                    }

                    // 倍率表示
                    Text("×\(String(format: "%.1f", scale))")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, horizontalPadding * 0.6)
                        .padding(.vertical, verticalPadding * 0.8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.2))
                        )
                        .accessibilityLabel("現在の倍率: \(String(format: "%.1f", scale))倍")
                    }
                    .padding(.trailing, horizontalPadding * 0.6)
                    .padding(.bottom, verticalPadding * 1.2)
                }
            }

            // 上部コントロール（オーバーレイ）
            VStack {
                    HStack {
                        // 左：残り時間表示
                        Text(formattedRemainingTime)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, horizontalPadding * 0.6)
                            .padding(.vertical, verticalPadding * 0.8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.7))
                            )
                            .padding(.leading, horizontalPadding)
                            .accessibilityLabel("残り時間: \(formattedRemainingTime)")

                        Spacer()

                        // 中央：説明を見るボタン
                        Button(action: {
                            showExplanation = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 14))
                                Text(settingsManager.localizationManager.localizedString("explanation"))
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(Color("MainGreen"))
                            .padding(.horizontal, horizontalPadding * 0.8)
                            .padding(.vertical, verticalPadding * 0.8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                            )
                        }
                        .accessibilityLabel(settingsManager.localizationManager.localizedString("explanation"))

                        Spacer()

                        // 右：設定ボタン
                        Button(action: {
                            showSettings = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 16))
                                Text(settingsManager.localizationManager.localizedString("settings"))
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, horizontalPadding * 0.6)
                            .padding(.vertical, verticalPadding * 0.6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.25))
                            )
                        }
                        .padding(.trailing, horizontalPadding)
                        .accessibilityLabel(settingsManager.localizationManager.localizedString("settings"))
                    }
                    .padding(.top, verticalPadding)

                    Spacer()
                }

                // 下部：バツボタン（オーバーレイ）
                VStack {
                    Spacer()

                    Button(action: {
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: closeButtonSize * 0.057)
                                .frame(width: closeButtonSize, height: closeButtonSize)

                            Circle()
                                .fill(Color.white)
                                .frame(width: closeButtonSize * 0.857, height: closeButtonSize * 0.857)

                            Image(systemName: "xmark")
                                .font(.system(size: closeButtonSize * 0.4, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.bottom, screenHeight * 0.025)
                    .accessibilityLabel("閉じる")
                    .accessibilityHint("プレビューを閉じてカメラに戻ります")
                }

            // 画面録画警告（上部に常時表示）
            if securityManager.showRecordingWarning {
                VStack {
                    RecordingWarningView(settingsManager: settingsManager)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: securityManager.showRecordingWarning)
            }

            // スクリーンショット警告（中央にモーダル表示）
            if securityManager.showScreenshotWarning {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        securityManager.showScreenshotWarning = false
                    }

                ScreenshotWarningView(settingsManager: settingsManager)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(), value: securityManager.showScreenshotWarning)
            }
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(settingsManager: settingsManager, isTheaterMode: false)
        }
        .fullScreenCover(isPresented: $showExplanation) {
            ExplanationView(settingsManager: settingsManager)
        }
        .onReceive(timer) { _ in
            remainingTime = capturedImage.remainingTime
            imageManager.removeExpiredImages()

            // 画像が削除された場合は自動的に閉じる
            if imageManager.capturedImages.firstIndex(where: { $0.id == capturedImage.id }) == nil {
                dismiss()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = min(scale * 1.5, CGFloat(settingsManager.maxZoomFactor))
        }
    }

    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = max(scale / 1.5, 1.0)
            if scale == 1.0 {
                offset = .zero
                lastOffset = .zero
            }
        }
    }

    enum ZoomDirection {
        case `in`, out
    }

    private func startContinuousZoom(direction: ZoomDirection) {
        stopContinuousZoom()
        zoomStartTime = Date()
        continuousZoomCount = 0

        // カメラプレビューと同じ間隔（0.03秒）でスムーズに
        zoomTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            continuousZoomCount += 1

            // 経過時間を計算
            let elapsedTime = Date().timeIntervalSince(zoomStartTime ?? Date())

            // 基本ステップ（カメラプレビューと同じ）
            let baseStep: CGFloat = 0.03

            // 時間に応じた加速度（指数関数的に加速）
            let timeAcceleration = 1.0 + pow(min(elapsedTime / 2.0, 1.0), 1.5) * 3.0

            // 現在の倍率に応じた速度調整（カメラプレビューと同じ計算）
            let zoomMultiplier = max(1.0, sqrt(scale / 10.0))

            // 最終的なステップサイズ
            let step = baseStep * timeAcceleration * zoomMultiplier

            switch direction {
            case .in:
                scale = min(scale + step, CGFloat(settingsManager.maxZoomFactor))
            case .out:
                // ズームアウトは少し遅めに（70%）
                let outStep = step * 0.7
                scale = max(scale - outStep, 1.0)
                if scale == 1.0 {
                    offset = .zero
                    lastOffset = .zero
                }
            }

            if (direction == .in && scale >= CGFloat(settingsManager.maxZoomFactor)) ||
               (direction == .out && scale <= 1.0) {
                stopContinuousZoom()
            }
        }
    }

    private func stopContinuousZoom() {
        zoomTimer?.invalidate()
        zoomTimer = nil
        zoomStartTime = nil
        continuousZoomCount = 0
    }

    // 境界制約を適用したオフセットを計算（ベストプラクティスに基づく）
    private func boundedOffset(_ offset: CGSize, scale: CGFloat, imageSize: CGSize, viewSize: CGSize) -> CGSize {
        // スケールが1以下の場合はオフセットなし
        guard scale > 1.0 else {
            return .zero
        }

        // 画像のアスペクト比を維持した表示サイズを計算
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height

        let displaySize: CGSize
        if imageAspect > viewAspect {
            // 画像が横長：幅に合わせる
            displaySize = CGSize(width: viewSize.width, height: viewSize.width / imageAspect)
        } else {
            // 画像が縦長：高さに合わせる
            displaySize = CGSize(width: viewSize.height * imageAspect, height: viewSize.height)
        }

        // ズーム後のサイズ
        let scaledSize = CGSize(width: displaySize.width * scale, height: displaySize.height * scale)

        // 移動可能な最大範囲（拡大された部分の半分）
        let maxOffsetX = max(0, (scaledSize.width - viewSize.width) / 2)
        let maxOffsetY = max(0, (scaledSize.height - viewSize.height) / 2)

        // オフセットを範囲内にクランプ
        return CGSize(
            width: min(max(offset.width, -maxOffsetX), maxOffsetX),
            height: min(max(offset.height, -maxOffsetY), maxOffsetY)
        )
    }
}
