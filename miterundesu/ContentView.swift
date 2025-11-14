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
    @ObservedObject private var securityManager = SecurityManager.shared
    @StateObject private var settingsManager = SettingsManager()
    @ObservedObject private var onboardingManager = OnboardingManager.shared

    @State private var showSettings = false
    @State private var showExplanation = false
    @State private var selectedImage: CapturedImage? // サムネイルから開いた画像
    @State private var justCapturedImage: CapturedImage? // 撮影直後の画像

    // シアターモード用UI管理
    @State private var showUI = true
    @State private var uiHideTimer: Timer?

    // ロード画面管理
    @State private var isLoading = true

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height

            // レスポンシブなパディング値を計算（8ptグリッドシステムに準拠）
            // iPhone 15基準: 393pt幅、852pt高さ
            let horizontalPadding = screenWidth * 0.041  // 16pt (画面全体の統一マージン)
            let topPadding = screenHeight * 0.009       // 約8pt
            let bottomPadding = screenHeight * 0.009    // 約8pt
            let cameraHorizontalPadding = screenWidth * 0.031  // 12pt (カメラ周り)
            let cameraTopPadding = screenHeight * 0.009        // 約8pt
            let cameraBottomPadding = screenHeight * 0.014    // 約12pt（呼吸感を確保）

            ZStack {
                if isLoading {
                    // ロード画面
                    LoadingView(settingsManager: settingsManager)
                } else {
                    // メインカラー（背景）
                    (settingsManager.isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"))
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                // 上部コントロール（シアター、説明ボタン、設定）
                HStack(alignment: .center, spacing: 0) {
                    // 左：シアターモードトグル
                    TheaterModeToggle(
                        isTheaterMode: $settingsManager.isTheaterMode,
                        onToggle: {
                            handleTheaterModeChange()
                        },
                        settingsManager: settingsManager
                    )
                    .spotlight(id: "theater_toggle")
                    .padding(.leading, horizontalPadding)
                    .opacity(shouldShowUI ? 1 : 0)

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
                        .foregroundColor(settingsManager.isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                        )
                    }
                    .opacity(shouldShowUI ? 1 : 0)
                    .accessibilityLabel(settingsManager.localizationManager.localizedString("explanation"))

                    Spacer()

                    // 右：設定ボタン
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)

                            Text(settingsManager.localizationManager.localizedString("settings"))
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
                    .spotlight(id: "settings_button")
                    .padding(.trailing, horizontalPadding)
                    .opacity(shouldShowUI ? 1 : 0)
                    .accessibilityLabel(settingsManager.localizationManager.localizedString("settings"))
                }
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)

                // ヘッダー部分（無限スクロールとロゴ）
                HeaderView(settingsManager: settingsManager)
                    .spotlight(id: "scrolling_message")
                    .opacity(shouldShowUI ? 1 : 0)
                    .padding(.top, topPadding * 0.5)

                // カメラプレビュー領域
                Group {
                    if securityManager.hideContent {
                        // スクリーンショット検出時：完全に黒画面
                        Color.black
                            .aspectRatio(3/4, contentMode: .fit)
                    } else {
                        // 保護されたカメラプレビュー
                        ZStack(alignment: .bottomLeading) {
                            CameraPreviewWithZoom(
                                cameraManager: cameraManager,
                                isTheaterMode: $settingsManager.isTheaterMode,
                                onCapture: {
                                    capturePhoto()
                                }
                            )
                            .blur(radius: securityManager.isScreenRecording ? 30 : 0)

                            // 画面録画中の警告（中央）
                            if securityManager.isScreenRecording {
                                VStack(spacing: 12) {
                                    Image(systemName: "eye.slash.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)

                                    Text(settingsManager.localizationManager.localizedString("screen_recording_warning"))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.7))
                                )
                            }

                            // ウォーターマーク（カメラプレビュー上の左下）
                            WatermarkView(isDarkBackground: true)
                                .padding(.leading, screenWidth * 0.031)  // 12pt
                                .padding(.bottom, screenWidth * 0.031)   // 12pt
                                .opacity(shouldShowUI ? 1 : 0)
                                .allowsHitTesting(false) // タッチイベントを透過
                        }
                        .preventScreenCapture()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1) // カメラプレビューが優先的にスペースを取得
                .padding(.horizontal, cameraHorizontalPadding)
                .padding(.top, cameraTopPadding)
                .padding(.bottom, cameraBottomPadding)

                // フッター部分
                FooterView(
                    isTheaterMode: settingsManager.isTheaterMode,
                    currentZoom: cameraManager.currentZoom,
                    imageManager: imageManager,
                    securityManager: securityManager,
                    settingsManager: settingsManager,
                    cameraManager: cameraManager,
                    selectedImage: $selectedImage,
                    onCapture: {
                        capturePhoto()
                    },
                    screenWidth: screenWidth,
                    screenHeight: screenHeight
                )
                .opacity(shouldShowUI ? 1 : 0)
                }


                // シアターモード時のタップ領域
                if settingsManager.isTheaterMode && !showUI {
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

                // スポットライトチュートリアル（オーバーレイ）
                if onboardingManager.showFeatureHighlights && !isLoading {
                    SpotlightTutorialView(settingsManager: settingsManager)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: onboardingManager.showFeatureHighlights)
                }
                }
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(settingsManager: settingsManager, isTheaterMode: settingsManager.isTheaterMode)
        }
        .fullScreenCover(isPresented: $showExplanation) {
            ExplanationView(settingsManager: settingsManager)
        }
        .fullScreenCover(item: $selectedImage) { capturedImage in
            ImageGalleryView(
                imageManager: imageManager,
                settingsManager: settingsManager,
                initialImage: capturedImage
            )
            .environment(\.isPressMode, settingsManager.isPressMode)
        }
        .fullScreenCover(item: $justCapturedImage) { capturedImage in
            CapturedImagePreview(
                imageManager: imageManager,
                settingsManager: settingsManager,
                capturedImage: capturedImage
            )
            .environment(\.isPressMode, settingsManager.isPressMode)
        }
        .fullScreenCover(isPresented: $onboardingManager.showWelcomeScreen) {
            TutorialWelcomeView(settingsManager: settingsManager)
        }
        .preferredColorScheme(.dark)
        .environment(\.isPressMode, settingsManager.isPressMode)
        .onAppear {
            // 画面向きを縦向きに固定
            AppDelegate.orientationLock = .portrait

            // オンボーディング状態をチェック
            onboardingManager.checkOnboardingStatus()

            cameraManager.setupCamera()
            cameraManager.startSession()
            setupBackgroundNotification()
            // 設定から最大拡大率を適用
            cameraManager.setMaxZoomFactor(settingsManager.maxZoomFactor)
            // プレスモードをSecurityManagerに同期
            securityManager.isPressMode = settingsManager.isPressMode
            // 画面録画状態を再チェック（プレスモード同期後）
            securityManager.recheckScreenRecordingStatus()
        }
        .onChange(of: cameraManager.isCameraReady) { oldValue, newValue in
            if newValue {
                // カメラの準備ができたらローディングを終了
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
        .onDisappear {
            cameraManager.stopSession()
            stopUIHideTimer()
            // セキュリティデータのみクリア（画像はCoreDataで永続化）
            securityManager.clearSensitiveData()
        }
        .onChange(of: settingsManager.isTheaterMode) { oldValue, newValue in
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
        .onChange(of: settingsManager.isPressMode) { oldValue, newValue in
            // プレスモードが変更されたらSecurityManagerに同期
            securityManager.isPressMode = newValue
            print("📰 プレスモード: \(newValue ? "有効" : "無効")")
            // 画面録画状態を再チェック
            securityManager.recheckScreenRecordingStatus()

            // UI再構築中はローディング画面を表示
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
        .onChange(of: securityManager.hideContent) { oldValue, newValue in
            print("🔒 hideContent changed: \(oldValue) -> \(newValue)")

            if newValue {
                // コンテンツを隠す
                print("🔒 hideContent=true: 画像プレビューを閉じます")
                print("🔒 justCapturedImage: \(justCapturedImage != nil ? "あり" : "なし")")
                print("🔒 selectedImage: \(selectedImage != nil ? "あり" : "なし")")

                // 画像プレビューを閉じてカメラビューに戻る
                justCapturedImage = nil
                selectedImage = nil

                print("🔒 画像プレビューをnilに設定しました")
            } else {
                // コンテンツを再表示
                print("🔒 hideContent=false: コンテンツを再表示します")
            }
        }
        .onChange(of: securityManager.showScreenshotWarning) { oldValue, newValue in
            // 警告が閉じた時（false）に、確実にカメラプレビューに戻す
            if oldValue == true && newValue == false {
                print("🔒 スクリーンショット警告が閉じました - カメラプレビューに戻ります")
                // 明示的に画像プレビューを閉じる
                justCapturedImage = nil
                selectedImage = nil

                // カメラセッションの再起動は不要（preventScreenCapture()で保護されているため）
                print("🔒 カメラプレビューに復帰しました")
            }
        }
    }

    // UIを表示すべきかどうか
    private var shouldShowUI: Bool {
        !settingsManager.isTheaterMode || showUI
    }

    // シアターモード切り替え時の処理
    private func handleTheaterModeChange() {
        if settingsManager.isTheaterMode {
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
        // 二重チェック：既に撮影中またはシアターモードの場合は処理しない
        guard !cameraManager.isCapturing && !settingsManager.isTheaterMode else {
            print("⚠️ 撮影をスキップ: isCapturing=\(cameraManager.isCapturing), isTheaterMode=\(settingsManager.isTheaterMode)")
            return
        }

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
        // アプリがフォアグラウンドに復帰した時に期限切れ画像をチェック
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [imageManager, cameraManager] _ in
            print("⏯️ アプリがフォアグラウンドに復帰しました")
            // フォアグラウンド復帰時に期限切れ画像を削除
            imageManager.removeExpiredImages()

            // カメラセッションが停止している場合のみ再起動
            if !cameraManager.isSessionRunning {
                print("📷 カメラセッションが停止しているため再起動します")
                cameraManager.startSession()
            } else {
                print("📷 カメラセッションは既に実行中です")
            }
        }

        // アプリがバックグラウンドに移行する際にセキュリティデータのみクリア
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [securityManager] _ in
            print("⏸️ アプリが非アクティブになりました")
            securityManager.clearSensitiveData()
        }

        // アプリがバックグラウンドに移行した時
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("🔒 アプリがバックグラウンドに移行しました")
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @ObservedObject var settingsManager: SettingsManager

    var body: some View {
        VStack(spacing: 14) {
            // 無限スクロールテキスト
            InfiniteScrollingText(text: settingsManager.scrollingMessage)
                .frame(height: 32)
                .clipped()

            // ロゴ
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 28)
        }
    }
}

// MARK: - Infinite Scrolling Text
struct InfiniteScrollingText: View {
    let text: String
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let textWidth = text.widthOfString(usingFont: .systemFont(ofSize: 18))
            let spacing: CGFloat = 40
            let itemWidth = textWidth + spacing

            HStack(spacing: spacing) {
                // 十分な数のテキストを配置してシームレスなループを実現
                ForEach(0..<20, id: \.self) { _ in
                    Text(text)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize()
                }
            }
            .fixedSize()
            .offset(x: offset)
            .onAppear {
                // 初期位置を設定
                offset = 0

                // アニメーション開始
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // テキスト全体の長さに応じたアニメーション時間を計算（スピード一定）
                    let totalDistance = itemWidth * 10
                    let speed: CGFloat = 50 // ピクセル/秒
                    let duration = Double(totalDistance / speed)

                    withAnimation(
                        Animation.linear(duration: duration)
                            .repeatForever(autoreverses: false)
                    ) {
                        // ちょうど半分（10個分）移動させることでシームレスループ
                        offset = -itemWidth * 10
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
    @ObservedObject var settingsManager: SettingsManager

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
                Text(settingsManager.localizationManager.localizedString("theater_mode"))
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
        .accessibilityLabel(settingsManager.localizationManager.localizedString("theater_mode"))
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
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var cameraManager: CameraManager
    @Binding var selectedImage: CapturedImage?
    let onCapture: () -> Void
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    var body: some View {
        let horizontalPadding = screenWidth * 0.051  // 20pt (フッター左右マージン)
        let verticalTopPadding = screenHeight * 0.009  // 約8pt（カメラとフッターの間）
        let verticalBottomPadding = screenHeight * 0.023  // 約20pt（下部余白）
        let shutterSize = screenWidth * 0.22  // 画面幅の22%
        let thumbnailSize = screenWidth * 0.18  // 画面幅の18%

        ZStack {
            // シャッターボタン（中央）
            ShutterButton(
                isTheaterMode: isTheaterMode,
                onCapture: onCapture,
                settingsManager: settingsManager,
                cameraManager: cameraManager,
                buttonSize: shutterSize
            )

            HStack {
                // サムネイル（左下）
                ThumbnailView(
                    imageManager: imageManager,
                    securityManager: securityManager,
                    selectedImage: $selectedImage,
                    isTheaterMode: isTheaterMode,
                    settingsManager: settingsManager,
                    thumbnailSize: thumbnailSize
                )
                .padding(.leading, horizontalPadding)

                Spacer()

                // 倍率表示（右下）
                ZoomLevelView(zoomLevel: currentZoom)
                    .spotlight(id: "zoom_controls")
                    .padding(.trailing, horizontalPadding)
            }
        }
        .padding(.top, verticalTopPadding)
        .padding(.bottom, verticalBottomPadding)
    }
}

// MARK: - Shutter Button
struct ShutterButton: View {
    let isTheaterMode: Bool
    let onCapture: () -> Void
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var cameraManager: CameraManager
    let buttonSize: CGFloat

    var body: some View {
        let isDisabled = isTheaterMode || cameraManager.isCapturing

        VStack(spacing: 8) {
            Button(action: {
                // 二重チェック：無効状態でも実行しない
                guard !isDisabled else {
                    print("⚠️ シャッターボタン押下をスキップ: disabled状態")
                    return
                }
                onCapture()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: buttonSize * 0.057)  // 4/70 ≈ 0.057
                        .frame(width: buttonSize, height: buttonSize)

                    Circle()
                        .fill(isDisabled ? Color.gray : Color.white)
                        .frame(width: buttonSize * 0.857, height: buttonSize * 0.857)  // 60/70 ≈ 0.857
                }
            }
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.3 : 1.0)
            .accessibilityLabel(settingsManager.localizationManager.localizedString(isTheaterMode ? "capture_disabled" : (cameraManager.isCapturing ? "capturing" : "capture")))
            .accessibilityAddTraits(.isButton)
        }
    }
}

// MARK: - Thumbnail View
struct ThumbnailView: View {
    @ObservedObject var imageManager: ImageManager
    @ObservedObject var securityManager: SecurityManager
    @Binding var selectedImage: CapturedImage?
    let isTheaterMode: Bool
    @ObservedObject var settingsManager: SettingsManager
    let thumbnailSize: CGFloat

    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let cornerRadius = thumbnailSize * 0.167  // 10/60 ≈ 0.167
        let iconSize = thumbnailSize * 0.4  // 24/60 = 0.4
        let blurRadius = thumbnailSize * 0.167  // 10/60 ≈ 0.167

        if let latestImage = imageManager.capturedImages.first {
            Button(action: {
                if !isTheaterMode {
                    selectedImage = latestImage
                }
            }) {
                ZStack(alignment: .topTrailing) {
                    // 画像を表示（サムネイルは小さいので保護不要）
                    ZStack {
                        Image(uiImage: latestImage.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: thumbnailSize, height: thumbnailSize)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .blur(radius: securityManager.isScreenRecording ? blurRadius : 0)
                    }
                    .contextMenu { } // コンテキストメニューを無効化

                    // 残り時間バッジ（保護の外側）
                    TimeRemainingBadge(remainingTime: latestImage.remainingTime)
                }
            }
            .disabled(isTheaterMode)
            .opacity(isTheaterMode ? 0.3 : 1.0)
            .accessibilityLabel(settingsManager.localizationManager.localizedString(isTheaterMode ? "viewing_disabled" : "latest_image"))
            .onReceive(timer) { _ in
                currentTime = Date()
                imageManager.removeExpiredImages()
            }
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.2))
                .frame(width: thumbnailSize, height: thumbnailSize)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: iconSize))
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

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    @ObservedObject var settingsManager: SettingsManager

    var body: some View {
        ZStack {
            Color("MainGreen")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // ロゴ
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 32)

                // ローディングインジケーター
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 1)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }

                Text(settingsManager.localizationManager.localizedString("camera_preparing"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .onAppear {
                isAnimating = true
            }
        }
        .preferredColorScheme(.dark)
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
