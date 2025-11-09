//
//  CameraPreview.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import AVFoundation
import AVKit

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // プレビューレイヤーがまだ追加されていない場合は追加
        if context.coordinator.previewLayer == nil {
            let previewLayer = cameraManager.previewLayer
            context.coordinator.previewLayer = previewLayer
            uiView.layer.addSublayer(previewLayer)
        }

        // フレームを更新
        if let previewLayer = context.coordinator.previewLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = uiView.bounds
            CATransaction.commit()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
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
        ZStack(alignment: .bottomTrailing) {
            CameraPreview(cameraManager: cameraManager)
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
                .onCameraCaptureEvent { event in
                    // Camera Controlボタンの押下を検知
                    if event.phase == .ended && !isTheaterMode {
                        onCapture()
                    }
                }

            // カメラズームコントロール
            if !isTheaterMode {
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

                    // リセットボタン
                    Button(action: {
                        stopContinuousZoom()
                        cameraManager.smoothZoom(to: 1.0, duration: 0.3)
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
                    .accessibilityHint("カメラのズームを1倍に戻します")
                }
                .padding(.trailing, 12)
                .padding(.bottom, 12)
            }
        }
        .cornerRadius(20)
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
