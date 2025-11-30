//
//  CameraPreview.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import AVFoundation
import AVKit

struct CameraPreview: UIViewRepresentable, Equatable {
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = cameraManager.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        #if DEBUG
        print("📹 CameraPreview created")
        #endif
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // セッションが変わった場合のみ再割り当て（パフォーマンス最適化）
        guard uiView.videoPreviewLayer.session !== cameraManager.session else { return }

        #if DEBUG
        print("📹 Re-assigning camera session to preview layer")
        #endif
        uiView.videoPreviewLayer.session = cameraManager.session
    }

    // Equatableに準拠して不要な更新を防ぐ
    static func == (lhs: CameraPreview, rhs: CameraPreview) -> Bool {
        lhs.cameraManager === rhs.cameraManager
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        // 必要に応じて使用
    }

    // カスタムUIView - AVCaptureVideoPreviewLayerを直接layerClassとして使用
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

// MARK: - Camera Preview with Pinch Zoom Gesture
struct CameraPreviewWithZoom: View {
    @ObservedObject var cameraManager: CameraManager
    @Binding var isTheaterMode: Bool
    let onCapture: () -> Void

    @State private var lastZoomFactor: CGFloat = 1.0
    @State private var zoomTimer: Timer?
    @State private var zoomStartTime: Date?
    @State private var continuousZoomCount: Int = 0

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let buttonSize = screenWidth * 0.11        // 11%
            let iconSize = screenWidth * 0.05          // 5%
            let buttonSpacing = screenWidth * 0.03     // 3%
            let buttonPadding = screenWidth * 0.03     // 3%
            let cornerRadius = screenWidth * 0.05      // 5%

            ZStack(alignment: .bottomTrailing) {
                CameraPreview(cameraManager: cameraManager)
                    .equatable()
                    .frame(maxHeight: .infinity)
                    .aspectRatio(3/4, contentMode: .fit) // .photo プリセットは 4:3（縦向きなので 3:4）
                    .overlay(alignment: .bottomLeading) {
                        // ウォーターマーク（カメラプレビュー内の左下）
                        WatermarkView(isDarkBackground: true)
                            .padding(.leading, screenWidth * 0.04)
                            .padding(.bottom, screenWidth * 0.04)
                            .allowsHitTesting(false)
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                // シアターモード時もズームは有効（ピンチ操作のみ有効）
                                let delta = value / lastZoomFactor
                                lastZoomFactor = value
                                let newZoom = cameraManager.currentZoom * delta
                                cameraManager.zoom(factor: newZoom)
                            }
                            .onEnded { _ in
                                lastZoomFactor = 1.0
                            }
                    )
                    .modifier(CameraCaptureEventModifier(isTheaterMode: isTheaterMode, isCapturing: cameraManager.isCapturing, onCapture: onCapture))

                // カメラズームコントロール（シアターモードでも表示）
                VStack(spacing: buttonSpacing) {
                    // ズームイン
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: buttonSize, height: buttonSize)

                        Image(systemName: "plus")
                            .font(.system(size: iconSize, weight: .medium))
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
                    .accessibilityLabel(LocalizationManager.shared.localizedString("zoom_in"))
                    .accessibilityHint(LocalizationManager.shared.localizedString("zoom_in_hint"))

                    // ズームアウト
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: buttonSize, height: buttonSize)

                        Image(systemName: "minus")
                            .font(.system(size: iconSize, weight: .medium))
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
                    .accessibilityLabel(LocalizationManager.shared.localizedString("zoom_out"))
                    .accessibilityHint(LocalizationManager.shared.localizedString("zoom_out_hint"))

                    // リセットボタン
                    Button(action: {
                        stopContinuousZoom()
                        cameraManager.smoothZoom(to: 1.0, duration: 0.3)
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: buttonSize, height: buttonSize)

                            Image(systemName: "1.circle")
                                .font(.system(size: iconSize, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel(LocalizationManager.shared.localizedString("zoom_reset"))
                    .accessibilityHint(LocalizationManager.shared.localizedString("zoom_reset_camera_hint"))
                }
                .padding(.trailing, buttonPadding)
                .padding(.bottom, buttonPadding)
                .spotlight(id: "zoom_buttons")
            }
            .cornerRadius(cornerRadius)
        }
    }

    private func zoomIn() {
        let newZoom = min(cameraManager.currentZoom * 1.5, cameraManager.maxZoomFactor)
        cameraManager.zoom(factor: newZoom)
    }

    private func zoomOut() {
        let newZoom = max(cameraManager.currentZoom / 1.5, 1.0)
        cameraManager.zoom(factor: newZoom)
    }

    enum ZoomDirection {
        case `in`, out
    }

    private func startContinuousZoom(direction: ZoomDirection) {
        stopContinuousZoom()
        zoomStartTime = Date()
        continuousZoomCount = 0

        zoomTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            let currentZoom = cameraManager.currentZoom
            continuousZoomCount += 1

            // 経過時間を計算（秒）
            let elapsedTime = Date().timeIntervalSince(zoomStartTime ?? Date())

            // 基本ステップ（小さく開始）
            let baseStep: CGFloat = 0.03

            // 時間に応じた加速度（指数関数的に加速）
            // 0.5秒後から加速開始、2秒で約4倍速に
            let timeAcceleration = 1.0 + pow(min(elapsedTime / 2.0, 1.0), 1.5) * 3.0

            // 現在の倍率に応じた速度調整（高倍率では大きなステップ）
            // 10倍で2倍速、50倍で5倍速、100倍で10倍速
            let zoomMultiplier = max(1.0, sqrt(currentZoom / 10.0))

            // 最終的なステップサイズ
            let step = baseStep * timeAcceleration * zoomMultiplier

            let newZoom: CGFloat
            switch direction {
            case .in:
                newZoom = min(currentZoom + step, cameraManager.maxZoomFactor)
            case .out:
                // ズームアウトは少し遅めに（70%）
                let outStep = step * 0.7
                newZoom = max(currentZoom - outStep, 1.0)
            }

            cameraManager.zoom(factor: newZoom)

            // 上限・下限に達したらタイマーを停止
            if (direction == .in && newZoom >= cameraManager.maxZoomFactor) ||
               (direction == .out && newZoom <= 1.0) {
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

// MARK: - Camera Capture Event Modifier (iOS 18+)
struct CameraCaptureEventModifier: ViewModifier {
    let isTheaterMode: Bool
    let isCapturing: Bool
    let onCapture: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onCameraCaptureEvent { event in
                    // Camera Controlボタンの押下を検知（撮影中でない場合のみ）
                    if event.phase == .ended && !isTheaterMode && !isCapturing {
                        onCapture()
                    }
                }
        } else {
            content
        }
    }
}
