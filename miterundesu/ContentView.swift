//
//  ContentView.swift
//  miterundesu
//
//  Created by 鈴木我信 on 2025/11/09.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var imageManager = ImageManager()

    @State private var isTheaterMode = false
    @State private var showSettings = false
    @State private var showExplanation = false
    @State private var selectedImage: CapturedImage?

    var body: some View {
        ZStack {
            // メインカラー（背景）
            (isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー部分
                HeaderView(
                    isTheaterMode: isTheaterMode,
                    showExplanation: $showExplanation
                )

                Spacer()

                // カメラプレビュー領域
                CameraPreviewWithZoom(
                    cameraManager: cameraManager,
                    isTheaterMode: $isTheaterMode
                )
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .padding(.horizontal, 20)

                Spacer()

                // フッター部分
                FooterView(
                    isTheaterMode: isTheaterMode,
                    currentZoom: cameraManager.currentZoom,
                    imageManager: imageManager,
                    selectedImage: $selectedImage,
                    onCapture: {
                        capturePhoto()
                    }
                )
            }

            // 左上：シアターモードトグル
            VStack {
                HStack {
                    TheaterModeToggle(isTheaterMode: $isTheaterMode)
                        .padding(.leading, 20)
                        .padding(.top, 50)

                    Spacer()
                }
                Spacer()
            }

            // 右上：設定アイコン
            VStack {
                HStack {
                    Spacer()

                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .opacity(isTheaterMode ? 0.3 : 1.0)
                    }
                    .disabled(isTheaterMode)
                    .padding(.trailing, 20)
                    .padding(.top, 50)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsViewPlaceholder()
        }
        .sheet(isPresented: $showExplanation) {
            ExplanationViewPlaceholder(isTheaterMode: isTheaterMode)
        }
        .sheet(item: $selectedImage) { capturedImage in
            ImagePreviewView(capturedImage: capturedImage)
        }
        .onAppear {
            cameraManager.setupCamera()
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }

    private func capturePhoto() {
        cameraManager.capturePhoto { image in
            if let image = image {
                imageManager.addImage(image)
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let isTheaterMode: Bool
    @Binding var showExplanation: Bool

    var body: some View {
        VStack(spacing: 8) {
            // ロゴ
            Text("ミテルンデス")
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(.white)
                .padding(.top, 60)

            // 無限スクロールテキスト
            InfiniteScrollingText(text: "画像は保存できません。")
                .frame(height: 30)

            // 説明を見るボタン
            Button(action: {
                showExplanation = true
            }) {
                HStack(spacing: 4) {
                    Text("📘")
                    Text("説明を見る")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                )
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Infinite Scrolling Text
struct InfiniteScrollingText: View {
    let text: String
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let textWidth = text.widthOfString(usingFont: .systemFont(ofSize: 16))
            let screenWidth = geometry.size.width

            HStack(spacing: 40) {
                ForEach(0..<5, id: \.self) { _ in
                    Text(text)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .offset(x: offset)
            .onAppear {
                offset = screenWidth
                let totalDistance = screenWidth + textWidth + 40
                withAnimation(
                    Animation.linear(duration: 10)
                        .repeatForever(autoreverses: false)
                ) {
                    offset = -(textWidth + 40)
                }
            }
        }
    }
}

// MARK: - Theater Mode Toggle
struct TheaterModeToggle: View {
    @Binding var isTheaterMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: $isTheaterMode) {
                Text("シアターモード")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.orange))
            .frame(width: 160)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
        )
    }
}


// MARK: - Footer View
struct FooterView: View {
    let isTheaterMode: Bool
    let currentZoom: CGFloat
    @ObservedObject var imageManager: ImageManager
    @Binding var selectedImage: CapturedImage?
    let onCapture: () -> Void

    var body: some View {
        ZStack {
            // シャッターボタン（中央）
            ShutterButton(
                isTheaterMode: isTheaterMode,
                onCapture: onCapture
            )

            HStack {
                // サムネイル（左下）
                ThumbnailView(
                    imageManager: imageManager,
                    selectedImage: $selectedImage
                )
                .padding(.leading, 20)

                Spacer()

                // 倍率表示（右下）
                ZoomLevelView(zoomLevel: currentZoom)
                    .padding(.trailing, 20)
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Shutter Button
struct ShutterButton: View {
    let isTheaterMode: Bool
    let onCapture: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                onCapture()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 70, height: 70)

                    Circle()
                        .fill(isTheaterMode ? Color.gray : Color.white)
                        .frame(width: 60, height: 60)
                }
            }
            .disabled(isTheaterMode)
            .opacity(isTheaterMode ? 0.3 : 1.0)

            if isTheaterMode {
                Text("撮影不可")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Thumbnail View
struct ThumbnailView: View {
    @ObservedObject var imageManager: ImageManager
    @Binding var selectedImage: CapturedImage?

    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if let latestImage = imageManager.capturedImages.first {
            Button(action: {
                selectedImage = latestImage
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: latestImage.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                        )

                    // 残り時間バッジ
                    TimeRemainingBadge(remainingTime: latestImage.remainingTime)
                }
            }
            .onReceive(timer) { _ in
                currentTime = Date()
                imageManager.removeExpiredImages()
            }
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                )
        }
    }
}

// MARK: - Time Remaining Badge
struct TimeRemainingBadge: View {
    let remainingTime: TimeInterval

    var body: some View {
        Text(formattedTime)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.red.opacity(0.8))
            )
            .padding(4)
    }

    private var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Zoom Level View
struct ZoomLevelView: View {
    let zoomLevel: CGFloat

    var body: some View {
        Text("×\(String(format: "%.1f", zoomLevel))")
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.2))
            )
    }
}

// MARK: - Placeholder Views
struct SettingsViewPlaceholder: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("設定画面")
                    .font(.title)
                Text("Phase 6で実装")
                    .foregroundColor(.gray)
            }
            .navigationTitle("設定")
        }
    }
}

struct ExplanationViewPlaceholder: View {
    let isTheaterMode: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("撮影しているわけではなく、\n拡大して見ているんです。")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text(isTheaterMode ?
                    "このアプリは写真や映像を撮るためのものではありません。明るさを抑えた画面で、一時的に文字や作品を\"見やすく\"するために使用しています。保存・録画・共有は一切できません。周囲の方の迷惑にならないよう、光量を落として利用しています。" :
                    "ミテルンデスは、画像を保存・共有する機能を持たないアプリです。撮影ボタンを押しても写真は端末に保存されず、10分後に自動的に消去されます。プライバシーや著作権を守るための設計であり、あくまで\"見やすくするための補助ツール\"です。"
                )
                .font(.body)

                Spacer()

                VStack(spacing: 12) {
                    Link("miterundesu.jp", destination: URL(string: "https://miterundesu.jp")!)
                        .font(.system(size: 14))

                    HStack(spacing: 20) {
                        Link(destination: URL(string: "https://twitter.com")!) {
                            Image(systemName: "xmark")
                                .font(.system(size: 24))
                        }

                        Link(destination: URL(string: "https://instagram.com")!) {
                            Image(systemName: "camera")
                                .font(.system(size: 24))
                        }
                    }
                }
            }
            .padding()
        }
        .background(isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"))
    }
}

// MARK: - String Extension
extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}

#Preview {
    ContentView()
}
