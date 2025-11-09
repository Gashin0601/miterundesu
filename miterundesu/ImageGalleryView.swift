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

    @State private var currentIndex: Int = 0
    @State private var remainingTime: TimeInterval

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
            Color.black.ignoresSafeArea()

            if !imageManager.capturedImages.isEmpty && currentIndex < imageManager.capturedImages.count {
                TabView(selection: $currentIndex) {
                    ForEach(Array(imageManager.capturedImages.enumerated()), id: \.element.id) { index, capturedImage in
                        ZoomableImageView(
                            capturedImage: capturedImage,
                            maxZoom: settingsManager.maxZoomFactor
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()

                // 上部コントロール
                VStack {
                    HStack {
                        // 閉じるボタン（シャッターボタンと同じデザイン）
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
                        .padding()
                        .accessibilityLabel("閉じる")
                        .accessibilityHint("ギャラリーを閉じてメイン画面に戻ります")

                        Spacer()

                        // 残り時間表示
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
                                .padding()
                        }
                    }

                    Spacer()
                }

                // 画像インジケーター
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
                        .padding(.bottom, 40)
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
        .onChange(of: currentIndex) { oldValue, newValue in
            if newValue < imageManager.capturedImages.count {
                remainingTime = imageManager.capturedImages[newValue].remainingTime
            }
        }
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

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: capturedImage.image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 1), CGFloat(maxZoom))
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    // ダブルタップでズームリセット
                    withAnimation {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
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

            // ズームコントロール
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 16) {
                        // ズームイン
                        Button(action: {
                            zoomIn()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .accessibilityLabel("ズームイン")
                        .accessibilityHint("画像を1.5倍拡大します")

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
                            .accessibilityLabel("現在の倍率: \(String(format: "%.1f", scale))倍")

                        // ズームアウト
                        Button(action: {
                            zoomOut()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "minus")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .accessibilityLabel("ズームアウト")
                        .accessibilityHint("画像を縮小します")

                        // リセットボタン
                        Button(action: {
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
                    .padding(.bottom, 80)
                }
            }
        }
    }

    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = min(scale * 1.5, CGFloat(maxZoom))
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
}
