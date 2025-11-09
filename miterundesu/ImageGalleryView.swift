//
//  ImageGalleryView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

struct ImageGalleryView: View {
    @ObservedObject var imageManager: ImageManager
    @ObservedObject var settingsManager: SettingsManager
    let initialImage: CapturedImage
    @Environment(\.dismiss) var dismiss
    @StateObject private var securityManager = SecurityManager()

    @State private var currentIndex: Int = 0
    @State private var remainingTime: TimeInterval
    @State private var isZooming: Bool = false
    @State private var scrollPositionID: UUID?
    @State private var showExplanation = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(imageManager: ImageManager, settingsManager: SettingsManager, initialImage: CapturedImage) {
        self.imageManager = imageManager
        self.settingsManager = settingsManager
        self.initialImage = initialImage
        _remainingTime = State(initialValue: initialImage.remainingTime)

        // 初期画像のインデックスを取得
        if let index = imageManager.capturedImages.firstIndex(where: { $0.id == initialImage.id }) {
            _currentIndex = State(initialValue: index)
        }
    }

    var body: some View {
        ZStack {
            if !imageManager.capturedImages.isEmpty && currentIndex < imageManager.capturedImages.count {
                // 画像表示エリア（緑の背景・全画面）
                ZStack {
                    // 緑の背景
                    Color("MainGreen")
                        .ignoresSafeArea()

                    // 画像スクロールビュー
                    GeometryReader { geometry in
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 0) {
                                    ForEach(Array(imageManager.capturedImages.enumerated()), id: \.element.id) { index, capturedImage in
                                        ZoomableImageView(
                                            capturedImage: capturedImage,
                                            maxZoom: settingsManager.maxZoomFactor,
                                            isZooming: $isZooming
                                        )
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .id(capturedImage.id)
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .scrollTargetBehavior(.paging)
                            .scrollPosition(id: $scrollPositionID)
                            .scrollDisabled(isZooming)
                            .blur(radius: securityManager.isScreenRecording ? 50 : 0)
                            .onChange(of: scrollPositionID) { oldValue, newValue in
                                // スクロール位置からインデックスを更新
                                if let newID = newValue,
                                   let newIndex = imageManager.capturedImages.firstIndex(where: { $0.id == newID }) {
                                    currentIndex = newIndex
                                    remainingTime = imageManager.capturedImages[newIndex].remainingTime
                                }
                            }
                            .onAppear {
                                // 初期位置を設定
                                scrollPositionID = imageManager.capturedImages[safe: currentIndex]?.id
                            }
                    }

                    // 画面録画中の警告オーバーレイ
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
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.8))
                        )
                    }

                    // 上部コントロール（オーバーレイ）
                    VStack {
                        HStack {
                            // 左：残り時間表示
                            if currentIndex < imageManager.capturedImages.count {
                                Text(formattedRemainingTime)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.red.opacity(0.7))
                                    )
                                    .padding(.leading, 20)
                            }

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
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white)
                                )
                            }
                            .accessibilityLabel(settingsManager.localizationManager.localizedString("explanation"))

                            Spacer()

                            // 右：閉じるボタン
                            Button(action: {
                                dismiss()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                    Text(settingsManager.localizationManager.localizedString("close"))
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.25))
                                )
                            }
                            .padding(.trailing, 20)
                            .accessibilityLabel(settingsManager.localizationManager.localizedString("close"))
                        }
                        .padding(.top, 8)

                        Spacer()
                    }

                    // 画像インジケーター（オーバーレイ）
                    if imageManager.capturedImages.count > 1 {
                        VStack {
                            Spacer()

                            HStack(spacing: 8) {
                                ForEach(0..<imageManager.capturedImages.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.bottom, 16)
                        }
                    }
                }
            } else {
                // 画像が削除された場合
                VStack {
                    Text("画像が削除されました")
                        .font(.headline)
                        .foregroundColor(.white)

                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
            }
        }
        .fullScreenCover(isPresented: $showExplanation) {
            ExplanationView(settingsManager: settingsManager)
        }
        .onReceive(timer) { _ in
            if currentIndex < imageManager.capturedImages.count {
                remainingTime = imageManager.capturedImages[currentIndex].remainingTime
                imageManager.removeExpiredImages()

                // 現在の画像が削除された場合
                if imageManager.capturedImages.isEmpty {
                    dismiss()
                } else if currentIndex >= imageManager.capturedImages.count {
                    currentIndex = max(0, imageManager.capturedImages.count - 1)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Zoomable Image View
struct ZoomableImageView: View {
    let capturedImage: CapturedImage
    let maxZoom: Double
    @Binding var isZooming: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var zoomTimer: Timer?
    @State private var zoomStartTime: Date?
    @State private var continuousZoomCount: Int = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: capturedImage.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(scale)
                    .offset(offset)
                    .clipped()
                    .onAppear {
                    // 表示時にズーム状態をリセット
                    scale = 1.0
                    lastScale = 1.0
                    offset = .zero
                    lastOffset = .zero
                    isZooming = false
                }
                .highPriorityGesture(
                    MagnificationGesture(minimumScaleDelta: 0)
                        .onChanged { value in
                            isZooming = true
                            let delta = value / lastScale
                            lastScale = value
                            let newScale = min(max(scale * delta, 1), CGFloat(maxZoom))
                            scale = newScale
                            // スケール変更時にオフセットを境界内に制限
                            offset = boundedOffset(offset, scale: newScale, imageSize: capturedImage.image.size, viewSize: geometry.size)
                            lastOffset = offset
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if scale <= 1.0 {
                                    isZooming = false
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: scale > 1.0 ? 0 : 10)
                        .onChanged { value in
                            if scale > 1.0 {
                                isZooming = true
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if scale <= 1.0 {
                                    isZooming = false
                                }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    // ダブルタップでズームリセット
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isZooming = false
                    }
                }
                .allowsHitTesting(true)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            // 長押しを無効化
                        }
                )
                .contextMenu { }
                .onChange(of: scale) { oldValue, newValue in
                    if newValue > 1.0 {
                        isZooming = true
                    } else if newValue <= 1.0 {
                        isZooming = false
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        // スケール変更時にオフセットを境界内に調整
                        offset = boundedOffset(offset, scale: newValue, imageSize: capturedImage.image.size, viewSize: geometry.size)
                        lastOffset = offset
                    }
                }

                // 右側：ズームコントロールと倍率表示
                VStack(alignment: .trailing, spacing: 8) {
                    // ズームコントロールボタン
                    VStack(spacing: 12) {
                        // ズームイン
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 44, height: 44)

                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .onTapGesture {
                            zoomIn()
                        }
                        .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
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
                                .frame(width: 44, height: 44)

                            Image(systemName: "minus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .onTapGesture {
                            zoomOut()
                        }
                        .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
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
                                    .frame(width: 44, height: 44)

                                Image(systemName: "1.circle")
                                    .font(.system(size: 20, weight: .medium))
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
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .padding(.trailing, 12)
                .padding(.bottom, 12)
            }
        }
    }

    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = min(scale * 1.5, CGFloat(maxZoom))
        }
        isZooming = scale > 1.0
    }

    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = max(scale / 1.5, 1.0)
            if scale == 1.0 {
                offset = .zero
                lastOffset = .zero
                isZooming = false
            }
        }
    }

    enum ZoomDirection {
        case `in`, out
    }

    private func startContinuousZoom(direction: ZoomDirection) {
        stopContinuousZoom()
        isZooming = true
        zoomStartTime = Date()
        continuousZoomCount = 0

        zoomTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            continuousZoomCount += 1

            // 経過時間を計算（秒）
            let elapsedTime = Date().timeIntervalSince(zoomStartTime ?? Date())

            // 基本ステップ（画像は細かい制御が必要なのでカメラより小さめ）
            let baseStep: CGFloat = 0.02

            // 時間に応じた加速度（指数関数的に加速）
            let timeAcceleration = 1.0 + pow(min(elapsedTime / 2.0, 1.0), 1.5) * 3.0

            // 現在の倍率に応じた速度調整（高倍率では大きなステップ）
            let zoomMultiplier = max(1.0, sqrt(scale / 5.0))

            // 最終的なステップサイズ
            let step = baseStep * timeAcceleration * zoomMultiplier

            switch direction {
            case .in:
                scale = min(scale + step, CGFloat(maxZoom))
            case .out:
                // ズームアウトは少し遅めに（70%）
                let outStep = step * 0.7
                scale = max(scale - outStep, 1.0)
                if scale == 1.0 {
                    offset = .zero
                    lastOffset = .zero
                }
            }

            // 上限・下限に達したらタイマーを停止
            if (direction == .in && scale >= CGFloat(maxZoom)) ||
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

        if scale <= 1.0 {
            isZooming = false
        }
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

// MARK: - Array Extension for Safe Access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
