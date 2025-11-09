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
    @StateObject private var securityManager = SecurityManager()

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var remainingTime: TimeInterval
    @State private var zoomTimer: Timer?
    @State private var zoomStartTime: Date?
    @State private var continuousZoomCount: Int = 0

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(imageManager: ImageManager, settingsManager: SettingsManager, capturedImage: CapturedImage) {
        self.imageManager = imageManager
        self.settingsManager = settingsManager
        self.capturedImage = capturedImage
        _remainingTime = State(initialValue: capturedImage.remainingTime)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 画像表示
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
                                    scale = min(max(scale * delta, 1), CGFloat(settingsManager.maxZoomFactor))
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: scale > 1.0 ? 0 : 10)
                                .onChanged { value in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
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
                            }
                        }
                }
                .blur(radius: securityManager.isScreenRecording ? 50 : 0)

                // 画面録画中の警告
                if securityManager.isScreenRecording {
                    VStack(spacing: 20) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)

                        Text("画面録画中は表示できません")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("このアプリでは録画・保存はできません")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.8))
                    )
                }
            }

            // 上部：残り時間表示
            VStack {
                HStack {
                    Spacer()

                    Text(formattedRemainingTime)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.7))
                        )
                        .padding()
                }

                Spacer()
            }

            // 下部：バツボタン（シャッターと同じ位置・デザイン）
            VStack {
                Spacer()

                Button(action: {
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)

                        Image(systemName: "xmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.bottom, 40)
                .accessibilityLabel("閉じる")
                .accessibilityHint("プレビューを閉じてカメラに戻ります")
            }

            // 右側：ズームコントロール
            if scale > 1.0 || scale < CGFloat(settingsManager.maxZoomFactor) {
                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        VStack(spacing: 16) {
                            // ズームイン
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .medium))
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

                            // 現在の倍率表示
                            Text("×\(String(format: "%.1f", scale))")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.6))
                                )

                            // ズームアウト
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "minus")
                                    .font(.system(size: 24, weight: .medium))
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

                            // リセットボタン
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
                                        .frame(width: 50, height: 50)

                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            .accessibilityLabel("ズームリセット")
                            .accessibilityHint("画像の拡大を元に戻します")
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
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

        zoomTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            continuousZoomCount += 1

            let elapsedTime = Date().timeIntervalSince(zoomStartTime ?? Date())
            let baseStep: CGFloat = 0.02
            let timeAcceleration = 1.0 + pow(min(elapsedTime / 2.0, 1.0), 1.5) * 3.0
            let zoomMultiplier = max(1.0, sqrt(scale / 5.0))
            let step = baseStep * timeAcceleration * zoomMultiplier

            switch direction {
            case .in:
                scale = min(scale + step, CGFloat(settingsManager.maxZoomFactor))
            case .out:
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
}
