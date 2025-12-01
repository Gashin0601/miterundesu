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
    @Environment(\.isPressMode) var isPressMode
    @ObservedObject private var securityManager = SecurityManager.shared

    @State private var currentIndex: Int = 0
    @State private var remainingTime: TimeInterval
    @State private var isZooming: Bool = false
    @State private var scrollPositionID: UUID?
    @State private var showExplanation = false
    @State private var imageScales: [UUID: CGFloat] = [:]
    @State private var imageOffsets: [UUID: CGSize] = [:]
    @State private var zoomTimer: Timer?
    @State private var zoomStartTime: Date?
    @State private var savedScaleBeforeReset: CGFloat? = nil
    @State private var savedOffsetBeforeReset: CGSize? = nil

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
        GeometryReader { mainGeometry in
            let screenWidth = mainGeometry.size.width
            let screenHeight = mainGeometry.size.height

            // レスポンシブなサイズとパディング値を計算
            let horizontalPadding = screenWidth * 0.05  // 画面幅の5%
            let verticalPadding = screenHeight * 0.01   // 画面高さの1%
            let buttonSize = screenWidth * 0.11         // 画面幅の11% (44/390 ≈ 0.11)
            let indicatorSize = screenWidth * 0.02      // 画面幅の2%
            let warningPadding = screenWidth * 0.1      // 画面幅の10%

            ZStack {
                if !imageManager.capturedImages.isEmpty && currentIndex < imageManager.capturedImages.count {
                    // 画像表示エリア（緑の背景・全画面）
                    ZStack {
                        // 緑の背景
                        Color("MainGreen")
                            .ignoresSafeArea()

                    if securityManager.hideContent {
                        // スクリーンショット検出時：完全に黒画面
                        Color.black
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // 画像スクロールビュー
                        GeometryReader { geometry in
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 0) {
                                    ForEach(Array(imageManager.capturedImages.enumerated()), id: \.element.id) { index, capturedImage in
                                        ZoomableImageView(
                                            capturedImage: capturedImage,
                                            maxZoom: settingsManager.maxZoomFactor,
                                            isZooming: $isZooming,
                                            scale: Binding(
                                                get: { imageScales[capturedImage.id] ?? 1.0 },
                                                set: { imageScales[capturedImage.id] = $0 }
                                            ),
                                            offset: Binding(
                                                get: { imageOffsets[capturedImage.id] ?? .zero },
                                                set: { imageOffsets[capturedImage.id] = $0 }
                                            ),
                                            settingsManager: settingsManager,
                                            photoIndex: index,
                                            totalPhotos: imageManager.capturedImages.count
                                        )
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .id(capturedImage.id)
                                        .onAppear {
                                            // onAppearでは状態更新しない（onChange(of: scrollPositionID)で処理）
                                        }
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .scrollTargetBehavior(.paging)
                            .scrollPosition(id: $scrollPositionID)
                            .scrollDisabled(isZooming)
                            .accessibilityHidden(true) // VoiceOverからスクロールを隠す
                            .blur(radius: securityManager.isScreenRecording ? 50 : 0)
                            .modifier(ConditionalPreventCapture(isEnabled: !settingsManager.isPressMode))
                            .onChange(of: scrollPositionID) { oldValue, newValue in
                                // スクロール位置からインデックスを更新
                                if let newID = newValue,
                                   let newIndex = imageManager.capturedImages.firstIndex(where: { $0.id == newID }),
                                   newIndex != currentIndex {
                                    currentIndex = newIndex
                                    remainingTime = imageManager.capturedImages[newIndex].remainingTime

                                    // VoiceOver: 実行中の時のみアナウンス
                                    if UIAccessibility.isVoiceOverRunning {
                                        announcePhotoChange()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            UIAccessibility.post(notification: .layoutChanged, argument: nil)
                                        }
                                    }
                                }
                            }
                            .onAppear {
                                // 初期位置を設定
                                scrollPositionID = imageManager.capturedImages[safe: currentIndex]?.id
                            }
                    }

                    // VoiceOver用の現在画像情報（スクロールビューの代わり）
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityElement()
                        .accessibilityLabel(currentImageAccessibilityLabel)
                        .accessibilityValue(settingsManager.localizationManager.localizedString("zoom_scale_value").replacingOccurrences(of: "{zoom}", with: String(format: "%.1f", currentScale)))
                        .accessibilityHint(imageManager.capturedImages.count > 1 ? settingsManager.localizationManager.localizedString("three_finger_swipe_hint") : "")
                        .accessibilityScrollAction { edge in
                            // 3本指スワイプでページ切り替え
                            switch edge {
                            case .leading:
                                // 右から左へスワイプ = 次の写真
                                moveToNextPhoto()
                            case .trailing:
                                // 左から右へスワイプ = 前の写真
                                moveToPreviousPhoto()
                            default:
                                break
                            }
                        }
                        .allowsHitTesting(false)

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
                        .padding(warningPadding)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.8))
                        )
                        .accessibilityElement(children: .combine)
                    }

                    // 上部コントロール（オーバーレイ）
                    VStack {
                        HStack {
                            // 左：残り時間表示
                            if currentIndex < imageManager.capturedImages.count {
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
                                    .accessibilityLabel(spokenRemainingTime)
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
                                .padding(.horizontal, horizontalPadding * 0.8)
                                .padding(.vertical, verticalPadding * 0.8)
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
                                .padding(.horizontal, horizontalPadding * 0.6)
                                .padding(.vertical, verticalPadding * 0.6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.25))
                                )
                            }
                            .padding(.trailing, horizontalPadding)
                            .accessibilityLabel(settingsManager.localizationManager.localizedString("close"))
                        }
                        .padding(.top, verticalPadding)

                        Spacer()
                    }

                    // 画像インジケーター（オーバーレイ）
                    if imageManager.capturedImages.count > 1 {
                        VStack {
                            Spacer()

                            HStack(spacing: indicatorSize * 0.4) {
                                ForEach(Array(imageManager.capturedImages.enumerated()), id: \.element.id) { index, _ in
                                    Circle()
                                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                        .frame(width: indicatorSize, height: indicatorSize)
                                }
                            }
                            .id(currentIndex) // currentIndexが変わったら再描画
                            .padding(.bottom, verticalPadding * 1.6)
                            .accessibilityHidden(true)
                        }
                    }

                    // ズームコントロール（固定位置・オーバーレイ）
                    VStack {
                        Spacer()

                        HStack {
                            Spacer()

                            VStack(alignment: .trailing, spacing: buttonSize * 0.18) {
                                // ズームコントロールボタン
                                VStack(spacing: buttonSize * 0.27) {
                                    // ズームイン
                                    Button(action: {
                                        zoomIn()
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                                .frame(width: buttonSize, height: buttonSize)

                                            Image(systemName: "plus")
                                                .font(.system(size: buttonSize * 0.45, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .simultaneousGesture(
                                        LongPressGesture(minimumDuration: 0.5)
                                            .onChanged { _ in
                                                startContinuousZoom(direction: .in)
                                            }
                                    )
                                    .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                                        if !pressing {
                                            stopContinuousZoom()
                                        }
                                    }, perform: {})
                                    .accessibilityLabel(settingsManager.localizationManager.localizedString("zoom_in"))
                                    .accessibilityHint(settingsManager.localizationManager.localizedString("zoom_in_hint"))
                                    .accessibilityAddTraits(.isButton)

                                    // ズームアウト
                                    Button(action: {
                                        zoomOut()
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                                .frame(width: buttonSize, height: buttonSize)

                                            Image(systemName: "minus")
                                                .font(.system(size: buttonSize * 0.45, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .simultaneousGesture(
                                        LongPressGesture(minimumDuration: 0.5)
                                            .onChanged { _ in
                                                startContinuousZoom(direction: .out)
                                            }
                                    )
                                    .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                                        if !pressing {
                                            stopContinuousZoom()
                                        }
                                    }, perform: {})
                                    .accessibilityLabel(settingsManager.localizationManager.localizedString("zoom_out"))
                                    .accessibilityHint(settingsManager.localizationManager.localizedString("zoom_out_hint"))
                                    .accessibilityAddTraits(.isButton)

                                    // リセットボタン（1.circleアイコン）
                                    // タップ: 1倍にリセット
                                    // 長押し: 押している間だけ1倍、離すと元の倍率に戻る
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.6))
                                            .frame(width: buttonSize, height: buttonSize)

                                        Image(systemName: "1.circle")
                                            .font(.system(size: buttonSize * 0.45, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    .onTapGesture {
                                        // タップ: 完全にリセット
                                        savedScaleBeforeReset = nil
                                        savedOffsetBeforeReset = nil
                                        resetZoom()
                                    }
                                    .onLongPressGesture(minimumDuration: 0.2, pressing: { pressing in
                                        if pressing {
                                            // 長押し開始: 現在の倍率を保存して1倍に
                                            if currentScale > 1.0 {
                                                savedScaleBeforeReset = currentScale
                                                savedOffsetBeforeReset = currentOffset
                                                withAnimation(.easeOut(duration: 0.03)) {
                                                    if let id = currentImageID {
                                                        imageScales[id] = 1.0
                                                        imageOffsets[id] = .zero
                                                    }
                                                }
                                            }
                                        } else {
                                            // 長押し終了: 保存した倍率に戻す
                                            if let savedScale = savedScaleBeforeReset,
                                               let savedOffset = savedOffsetBeforeReset,
                                               let id = currentImageID {
                                                withAnimation(.easeOut(duration: 0.03)) {
                                                    imageScales[id] = savedScale
                                                    imageOffsets[id] = savedOffset
                                                }
                                                savedScaleBeforeReset = nil
                                                savedOffsetBeforeReset = nil
                                            }
                                        }
                                    }, perform: {})
                                    .accessibilityLabel(settingsManager.localizationManager.localizedString("zoom_reset"))
                                    .accessibilityHint(settingsManager.localizationManager.localizedString("zoom_reset_hint"))
                                    .accessibilityAddTraits(.isButton)
                                }

                                // 倍率表示
                                Text("×\(String(format: "%.1f", currentScale))")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, horizontalPadding * 0.6)
                                    .padding(.vertical, verticalPadding * 0.8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.2))
                                    )
                                    .accessibilityLabel(settingsManager.localizationManager.localizedString("current_zoom_accessibility").replacingOccurrences(of: "{zoom}", with: String(format: "%.1f", currentScale)))
                            }
                            .padding(.trailing, horizontalPadding * 0.6)
                            .padding(.bottom, screenHeight * 0.06)
                        }
                    }

                        // ウォーターマークオーバーレイ（左下・二重保護）
                        VStack {
                            Spacer()

                            HStack {
                                WatermarkView(isDarkBackground: true)
                                    .padding(.leading, horizontalPadding * 0.6)
                                    .padding(.bottom, screenHeight * 0.06)
                                    .accessibilityHidden(true)

                                Spacer()
                            }
                        }
                    }
                }
                } else {
                // 画像が削除された場合
                VStack {
                    Text(settingsManager.localizationManager.localizedString("image_deleted"))
                        .font(.headline)
                        .foregroundColor(.white)

                    Button(settingsManager.localizationManager.localizedString("close")) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(galleryAccessibilityLabel)
        .accessibilityScrollAction { edge in
            // ビュー全体で3本指スワイプによるページ切り替えを有効化
            switch edge {
            case .leading:
                moveToNextPhoto()
            case .trailing:
                moveToPreviousPhoto()
            default:
                break
            }
        }
        .onAppear {
            // VoiceOver: ギャラリー開始時のアナウンス
            announceGalleryOpened()
        }
    }

    private var galleryAccessibilityLabel: String {
        let photoGallery = settingsManager.localizationManager.localizedString("photo_gallery")
        let photoCount = settingsManager.localizationManager.localizedString("photo_count")
            .replacingOccurrences(of: "{count}", with: "\(imageManager.capturedImages.count)")
        return "\(photoGallery)、\(photoCount)"
    }

    private var currentImageAccessibilityLabel: String {
        guard currentIndex < imageManager.capturedImages.count else {
            return settingsManager.localizationManager.localizedString("no_images")
        }
        let capturedImage = imageManager.capturedImages[currentIndex]
        let capturedPhoto = settingsManager.localizationManager.localizedString("captured_photo")
        let photoNumber = settingsManager.localizationManager.localizedString("photo_number")
            .replacingOccurrences(of: "{current}", with: "\(currentIndex + 1)")
            .replacingOccurrences(of: "{total}", with: "\(imageManager.capturedImages.count)")

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let timeString = dateFormatter.string(from: capturedImage.capturedAt)

        let capturedAt = settingsManager.localizationManager.localizedString("captured_at")
            .replacingOccurrences(of: "{time}", with: timeString)

        return "\(capturedPhoto)、\(photoNumber)、\(capturedAt)"
    }

    private func announceGalleryOpened() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let announcement = galleryAccessibilityLabel
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    private func announcePhotoChange() {
        let message = settingsManager.localizationManager.localizedString("moved_to_photo")
            .replacingOccurrences(of: "{number}", with: "\(currentIndex + 1)")
            .replacingOccurrences(of: "{total}", with: "\(imageManager.capturedImages.count)")
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    private func moveToNextPhoto() {
        if currentIndex < imageManager.capturedImages.count - 1 {
            currentIndex += 1
            scrollPositionID = imageManager.capturedImages[safe: currentIndex]?.id
            remainingTime = imageManager.capturedImages[currentIndex].remainingTime
            announcePhotoChange()
        }
    }

    private func moveToPreviousPhoto() {
        if currentIndex > 0 {
            currentIndex -= 1
            scrollPositionID = imageManager.capturedImages[safe: currentIndex]?.id
            remainingTime = imageManager.capturedImages[currentIndex].remainingTime
            announcePhotoChange()
        }
    }

    private var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var spokenRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return settingsManager.localizationManager.localizedString("time_remaining_spoken")
            .replacingOccurrences(of: "{minutes}", with: String(minutes))
            .replacingOccurrences(of: "{seconds}", with: String(seconds))
    }

    private var currentImageID: UUID? {
        guard currentIndex < imageManager.capturedImages.count else { return nil }
        return imageManager.capturedImages[currentIndex].id
    }

    private var currentScale: CGFloat {
        guard let id = currentImageID else { return 1.0 }
        return imageScales[id] ?? 1.0
    }

    private var currentOffset: CGSize {
        guard let id = currentImageID else { return .zero }
        return imageOffsets[id] ?? .zero
    }

    private func zoomIn() {
        guard let id = currentImageID else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            let currentScale = imageScales[id] ?? 1.0
            imageScales[id] = min(currentScale * 1.5, CGFloat(settingsManager.maxZoomFactor))
        }
        isZooming = (imageScales[id] ?? 1.0) > 1.0
        announceZoomChange()
    }

    private func zoomOut() {
        guard let id = currentImageID else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            let currentScale = imageScales[id] ?? 1.0
            imageScales[id] = max(currentScale / 1.5, 1.0)
            if imageScales[id] == 1.0 {
                imageOffsets[id] = .zero
                isZooming = false
            }
        }
        announceZoomChange()
    }

    private func resetZoom() {
        guard let id = currentImageID else { return }
        stopContinuousZoom()
        withAnimation {
            imageScales[id] = 1.0
            imageOffsets[id] = .zero
        }
        isZooming = false
        let message = settingsManager.localizationManager.localizedString("zoom_reset_announced")
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func announceZoomChange() {
        let zoomString = String(format: "%.1f", currentScale)
        let message = settingsManager.localizationManager.localizedString("zoomed_to")
            .replacingOccurrences(of: "{zoom}", with: zoomString)
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    enum ZoomDirection {
        case `in`, out
    }

    private func startContinuousZoom(direction: ZoomDirection) {
        guard let id = currentImageID else { return }
        stopContinuousZoom()
        isZooming = true
        zoomStartTime = Date()

        // カメラプレビューと同じ間隔（0.03秒）でスムーズに
        zoomTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            let currentScale = imageScales[id] ?? 1.0

            // 経過時間を計算
            let elapsedTime = Date().timeIntervalSince(zoomStartTime ?? Date())

            // 基本ステップ（カメラプレビューと同じ）
            let baseStep: CGFloat = 0.03

            // 時間に応じた加速度（指数関数的に加速）
            let timeAcceleration = 1.0 + pow(min(elapsedTime / 2.0, 1.0), 1.5) * 3.0

            // 現在の倍率に応じた速度調整（カメラプレビューと同じ計算）
            let zoomMultiplier = max(1.0, sqrt(currentScale / 10.0))

            // 最終的なステップサイズ
            let step = baseStep * timeAcceleration * zoomMultiplier

            switch direction {
            case .in:
                imageScales[id] = min(currentScale + step, CGFloat(settingsManager.maxZoomFactor))
            case .out:
                // ズームアウトは少し遅めに（70%）
                let outStep = step * 0.7
                imageScales[id] = max(currentScale - outStep, 1.0)
                if imageScales[id] == 1.0 {
                    imageOffsets[id] = .zero
                }
            }

            if (direction == .in && (imageScales[id] ?? 1.0) >= CGFloat(settingsManager.maxZoomFactor)) ||
               (direction == .out && (imageScales[id] ?? 1.0) <= 1.0) {
                stopContinuousZoom()
            }
        }
    }

    private func stopContinuousZoom() {
        zoomTimer?.invalidate()
        zoomTimer = nil
        zoomStartTime = nil

        if let id = currentImageID, (imageScales[id] ?? 1.0) <= 1.0 {
            isZooming = false
        }
    }
}

// MARK: - Zoomable Image View
struct ZoomableImageView: View {
    let capturedImage: CapturedImage
    let maxZoom: Double
    @Binding var isZooming: Bool
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    let settingsManager: SettingsManager
    let photoIndex: Int
    let totalPhotos: Int
    @Environment(\.isPressMode) var isPressMode

    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero

    private var imageAccessibilityLabel: String {
        let capturedPhoto = settingsManager.localizationManager.localizedString("captured_photo")
        let photoNumber = settingsManager.localizationManager.localizedString("photo_number")
            .replacingOccurrences(of: "{current}", with: "\(photoIndex + 1)")
            .replacingOccurrences(of: "{total}", with: "\(totalPhotos)")

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let timeString = dateFormatter.string(from: capturedImage.capturedAt)

        let capturedAt = settingsManager.localizationManager.localizedString("captured_at")
            .replacingOccurrences(of: "{time}", with: timeString)

        return "\(capturedPhoto)、\(photoNumber)、\(capturedAt)"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 画像
                Image(uiImage: capturedImage.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(scale, anchor: .center)
                    .offset(offset)
                    .clipped()
                    .highPriorityGesture(
                        MagnifyGesture(minimumScaleDelta: 0)
                            .onChanged { value in
                                isZooming = true
                                let delta = value.magnification / lastScale
                                lastScale = value.magnification
                                let newScale = min(max(scale * delta, 1), CGFloat(maxZoom))

                                // ピンチ位置を基準にズーム（アンカーポイント計算）
                                let anchor = value.startAnchor
                                let anchorPoint = CGPoint(
                                    x: (anchor.x - 0.5) * geometry.size.width,
                                    y: (anchor.y - 0.5) * geometry.size.height
                                )

                                // アンカーポイントを固定するようにオフセットを調整
                                let scaleDiff = newScale / scale
                                var newOffset = CGSize(
                                    width: offset.width * scaleDiff - anchorPoint.x * (scaleDiff - 1),
                                    height: offset.height * scaleDiff - anchorPoint.y * (scaleDiff - 1)
                                )

                                scale = newScale
                                // スケール変更時にオフセットを境界内に制限
                                newOffset = boundedOffset(newOffset, scale: newScale, imageSize: capturedImage.image.size, viewSize: geometry.size)
                                offset = newOffset
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
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                // 長押しを無効化
                            }
                    )
                    .contextMenu { }

                // ズーム時のドラッグ・ピンチ用オーバーレイ（常に存在、scale > 1.0の時のみヒットテスト有効）
                Color.clear
                    .contentShape(Rectangle())
                    .allowsHitTesting(scale > 1.0)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                guard scale > 1.0 else { return }
                                isZooming = true
                                let newOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                offset = boundedOffset(newOffset, scale: scale, imageSize: capturedImage.image.size, viewSize: geometry.size)
                            }
                            .onEnded { _ in
                                guard scale > 1.0 else { return }
                                lastOffset = offset
                            }
                    )
                    .simultaneousGesture(
                        MagnifyGesture(minimumScaleDelta: 0)
                            .onChanged { value in
                                guard scale > 1.0 else { return }
                                let delta = value.magnification / lastScale
                                lastScale = value.magnification
                                let newScale = min(max(scale * delta, 1), CGFloat(maxZoom))

                                // ピンチ位置を基準にズーム
                                let anchor = value.startAnchor
                                let anchorPoint = CGPoint(
                                    x: (anchor.x - 0.5) * geometry.size.width,
                                    y: (anchor.y - 0.5) * geometry.size.height
                                )

                                let scaleDiff = newScale / scale
                                var newOffset = CGSize(
                                    width: offset.width * scaleDiff - anchorPoint.x * (scaleDiff - 1),
                                    height: offset.height * scaleDiff - anchorPoint.y * (scaleDiff - 1)
                                )

                                scale = newScale
                                newOffset = boundedOffset(newOffset, scale: newScale, imageSize: capturedImage.image.size, viewSize: geometry.size)
                                offset = newOffset
                                lastOffset = offset
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                if scale <= 1.0 {
                                    isZooming = false
                                }
                            }
                    )
            }
            .accessibilityElement()
            .accessibilityLabel(imageAccessibilityLabel)
            .accessibilityValue(settingsManager.localizationManager.localizedString("zoom_scale_value").replacingOccurrences(of: "{zoom}", with: String(format: "%.1f", scale)))
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
