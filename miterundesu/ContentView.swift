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
    @State private var selectedImage: CapturedImage? // サムネイルから開いた画像
    @State private var justCapturedImage: CapturedImage? // 撮影直後の画像

    // シアターモード用UI管理
    @State private var showUI = true
    @State private var uiHideTimer: Timer?

    var body: some View {
        ZStack {
            // メインカラー（背景）
            (isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 上部コントロール（シアター、ロゴ、設定）
                HStack(alignment: .center, spacing: 0) {
                    // 左：シアターモードトグル
                    TheaterModeToggle(
                        isTheaterMode: $isTheaterMode,
                        onToggle: {
                            handleTheaterModeChange()
                        }
                    )
                    .padding(.leading, 20)
                    .opacity(shouldShowUI ? 1 : 0)

                    Spacer()

                    // 中央：ロゴ
                    Text("ミテルンデス")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .opacity(shouldShowUI ? 1 : 0)

                    Spacer()

                    // 右：設定ボタン
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)

                            Text("設定")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.25))
                        )
                    }
                    .padding(.trailing, 20)
                    .opacity(shouldShowUI ? 1 : 0)
                    .accessibilityLabel("設定")
                    .accessibilityHint("アプリの設定画面を開きます")
                }
                .padding(.top, 8)
                .padding(.bottom, 8)

                // ヘッダー部分（無限スクロールと説明ボタンのみ）
                HeaderView(
                    isTheaterMode: isTheaterMode,
                    showExplanation: $showExplanation
                )
                .opacity(shouldShowUI ? 1 : 0)
                .padding(.top, 4)

                // カメラプレビュー領域
                ZStack {
                    CameraPreviewWithZoom(
                        cameraManager: cameraManager,
                        isTheaterMode: $isTheaterMode,
                        onCapture: {
                            capturePhoto()
                        }
                    )
                    .blur(radius: securityManager.isScreenRecording ? 30 : 0)

                    // 画面録画中の警告
                    if securityManager.isScreenRecording {
                        VStack(spacing: 12) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)

                            Text("録画中は非表示")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // フッター部分
                FooterView(
                    isTheaterMode: isTheaterMode,
                    currentZoom: cameraManager.currentZoom,
                    imageManager: imageManager,
                    securityManager: securityManager,
                    selectedImage: $selectedImage,
                    onCapture: {
                        capturePhoto()
                    }
                )
                .opacity(shouldShowUI ? 1 : 0)
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
        .fullScreenCover(item: $selectedImage) { capturedImage in
            ImageGalleryView(
                imageManager: imageManager,
                settingsManager: settingsManager,
                initialImage: capturedImage
            )
        }
        .fullScreenCover(item: $justCapturedImage) { capturedImage in
            CapturedImagePreview(
                imageManager: imageManager,
                settingsManager: settingsManager,
                capturedImage: capturedImage
            )
        }
        .preferredColorScheme(.dark)
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
                // 撮影後、自動的に撮影直後プレビューを表示
                if let latestImage = imageManager.capturedImages.first {
                    justCapturedImage = latestImage
                }
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
        VStack(spacing: 10) {
            // 無限スクロールテキスト
            InfiniteScrollingText(text: "画像は保存できません。")
                .frame(height: 28)
                .clipped()

            // 説明を見るボタン
            Button(action: {
                showExplanation = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 14))
                    Text("説明を見る")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                )
            }
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
            let spacing: CGFloat = 40
            let itemWidth = textWidth + spacing
            let screenWidth = geometry.size.width

            HStack(spacing: spacing) {
                // 2セット表示して途切れないループを実現
                ForEach(0..<10, id: \.self) { _ in
                    Text(text)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize()
                }
            }
            .fixedSize()
            .offset(x: offset)
            .onAppear {
                // 初期位置を画面右端に設定
                offset = screenWidth

                // アニメーション開始を少し遅延
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(
                        Animation.linear(duration: 20)
                            .repeatForever(autoreverses: false)
                    ) {
                        offset = -(itemWidth * 5)
                    }
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
        Button(action: {
            isTheaterMode.toggle()
            onToggle()
        }) {
            HStack(spacing: 5) {
                // カスタムアイコン
                TheaterModeIcon(isTheaterMode: isTheaterMode)
                    .frame(width: 18, height: 18)

                // テキスト
                Text("シアター")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.25))
            )
        }
        .accessibilityLabel("シアターモード")
        .accessibilityHint(isTheaterMode ? "シアターモードをオフにします" : "映画館や美術館などで使用するシアターモードをオンにします")
    }
}

// MARK: - Theater Mode Icon
struct TheaterModeIcon: View {
    let isTheaterMode: Bool

    var body: some View {
        ZStack {
            // 白い円の背景
            Circle()
                .fill(Color.white)

            // 左上から右下の対角線で分割
            GeometryReader { geometry in
                let size = geometry.size.width

                // 左上半分（通常時：オレンジ、シアター時：緑）
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: size, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: size))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                }
                .fill(isTheaterMode ? Color("MainGreen") : Color("TheaterOrange"))

                // 右下半分（通常時：緑、シアター時：オレンジ）
                Path { path in
                    path.move(to: CGPoint(x: size, y: 0))
                    path.addLine(to: CGPoint(x: size, y: size))
                    path.addLine(to: CGPoint(x: 0, y: size))
                    path.addLine(to: CGPoint(x: size, y: 0))
                }
                .fill(isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"))

                // 左上から右下への白い境界線
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: size, y: size))
                }
                .stroke(Color.white, lineWidth: 1.2)
            }
            .clipShape(Circle())

            // 中央にシンボルを表示（白い縁取り付き）
            ZStack {
                // 白い縁取り
                Image(systemName: isTheaterMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: -0.4, y: 0)
                Image(systemName: isTheaterMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: 0.4, y: 0)
                Image(systemName: isTheaterMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: 0, y: -0.4)
                Image(systemName: isTheaterMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: 0, y: 0.4)

                // メインアイコン
                Image(systemName: isTheaterMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"))
            }

            // 円全体に薄い枠線
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        }
    }
}


// MARK: - Footer View
struct FooterView: View {
    let isTheaterMode: Bool
    let currentZoom: CGFloat
    @ObservedObject var imageManager: ImageManager
    @ObservedObject var securityManager: SecurityManager
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
                    securityManager: securityManager,
                    selectedImage: $selectedImage
                )
                .padding(.leading, 16)

                Spacer()

                // 倍率表示（右下）
                ZoomLevelView(zoomLevel: currentZoom)
                    .padding(.trailing, 16)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
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
    @ObservedObject var securityManager: SecurityManager
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
                        .blur(radius: securityManager.isScreenRecording ? 10 : 0)
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
