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
    @StateObject private var securityManager = SecurityManager()
    @StateObject private var settingsManager = SettingsManager()

    @State private var isTheaterMode = false
    @State private var showSettings = false
    @State private var showExplanation = false
    @State private var selectedImage: CapturedImage?

    // シアターモード用UI管理
    @State private var showUI = true
    @State private var uiHideTimer: Timer?

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
                .opacity(shouldShowUI ? 1 : 0)

                Spacer()

                // カメラプレビュー領域
                CameraPreviewWithZoom(
                    cameraManager: cameraManager,
                    isTheaterMode: $isTheaterMode
                )
                .frame(maxWidth: .infinity)
                .frame(height: 500)
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
                .opacity(shouldShowUI ? 1 : 0)
            }

            // 左上：シアターモードトグル
            VStack {
                HStack {
                    TheaterModeToggle(
                        isTheaterMode: $isTheaterMode,
                        onToggle: {
                            handleTheaterModeChange()
                        }
                    )
                    .padding(.leading, 20)
                    .padding(.top, 50)
                    .opacity(shouldShowUI ? 1 : 0)

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
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 50)
                    .opacity(shouldShowUI ? 1 : 0)
                    .accessibilityLabel("設定")
                    .accessibilityHint("アプリの設定画面を開きます")
                }
                Spacer()
            }

            // シアターモード時のタップ領域
            if isTheaterMode && !showUI {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showUITemporarily()
                    }
            }

            // 画面録画警告（上部に常時表示）
            if securityManager.showRecordingWarning {
                VStack {
                    RecordingWarningView()
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

                ScreenshotWarningView()
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(), value: securityManager.showScreenshotWarning)
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(settingsManager: settingsManager, isTheaterMode: isTheaterMode)
        }
        .fullScreenCover(isPresented: $showExplanation) {
            ExplanationView(isTheaterMode: isTheaterMode)
        }
        .sheet(item: $selectedImage) { capturedImage in
            ImageGalleryView(
                imageManager: imageManager,
                settingsManager: settingsManager,
                initialImage: capturedImage
            )
        }
        .onAppear {
            cameraManager.setupCamera()
            cameraManager.startSession()
            setupBackgroundNotification()
            // 設定から最大拡大率を適用
            cameraManager.setMaxZoomFactor(settingsManager.maxZoomFactor)
        }
        .onDisappear {
            cameraManager.stopSession()
            stopUIHideTimer()
            // セキュリティ：メモリクリア
            imageManager.clearAllImages()
            securityManager.clearSensitiveData()
        }
        .onChange(of: isTheaterMode) { oldValue, newValue in
            if !newValue {
                // 通常モードに戻ったらUIを表示し、タイマー停止
                showUI = true
                stopUIHideTimer()
            }
        }
        .onChange(of: settingsManager.maxZoomFactor) { oldValue, newValue in
            // 最大拡大率が変更されたらカメラに適用
            cameraManager.setMaxZoomFactor(newValue)
        }
    }

    // UIを表示すべきかどうか
    private var shouldShowUI: Bool {
        !isTheaterMode || showUI
    }

    // シアターモード切り替え時の処理
    private func handleTheaterModeChange() {
        if isTheaterMode {
            // シアターモードON: UIを表示してタイマー開始
            showUI = true
            startUIHideTimer()
        } else {
            // シアターモードOFF: タイマー停止
            stopUIHideTimer()
        }
    }

    // UIを一時的に表示
    private func showUITemporarily() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showUI = true
        }
        startUIHideTimer()
    }

    // UI非表示タイマー開始
    private func startUIHideTimer() {
        stopUIHideTimer()

        uiHideTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                showUI = false
            }
        }
    }

    // UI非表示タイマー停止
    private func stopUIHideTimer() {
        uiHideTimer?.invalidate()
        uiHideTimer = nil
    }

    private func capturePhoto() {
        cameraManager.capturePhoto { image in
            if let image = image {
                imageManager.addImage(image)
            }
        }
    }

    // バックグラウンド通知の設定
    private func setupBackgroundNotification() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppWillResignActive"),
            object: nil,
            queue: .main
        ) { _ in
            // アプリがバックグラウンドに移行する際にメモリクリア
            imageManager.clearAllImages()
            securityManager.clearSensitiveData()
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
                .padding(.top, 80)

            // 無限スクロールテキスト
            InfiniteScrollingText(text: "画像は保存できません。")
                .frame(height: 30)
                .clipped()

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
            .accessibilityLabel("説明を見る")
            .accessibilityHint("アプリの使い方と注意事項を表示します")
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
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: Binding(
                get: { isTheaterMode },
                set: { newValue in
                    isTheaterMode = newValue
                    onToggle()
                }
            )) {
                Text("シアターモード")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.orange))
            .frame(width: 160)
            .accessibilityLabel("シアターモード")
            .accessibilityHint(isTheaterMode ? "シアターモードをオフにします" : "映画館や美術館などで使用するシアターモードをオンにします")
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
        .padding(.bottom, 20)
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
            .accessibilityLabel(isTheaterMode ? "撮影不可" : "シャッターボタン")
            .accessibilityHint(isTheaterMode ? "シアターモードでは撮影できません" : "タップして写真を撮影します。画像は10分後に自動削除されます")
            .accessibilityAddTraits(.isButton)

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
                        // コンテキストメニューを無効化
                        .contextMenu { }

                    // 残り時間バッジ
                    TimeRemainingBadge(remainingTime: latestImage.remainingTime)
                }
            }
            .accessibilityLabel("最新の撮影画像")
            .accessibilityHint("タップして撮影した画像を表示します。残り時間: \(formattedTime(latestImage.remainingTime))")
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

    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d分%02d秒", minutes, seconds)
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
