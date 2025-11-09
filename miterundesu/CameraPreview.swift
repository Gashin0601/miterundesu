//
//  CameraPreview.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = cameraManager.previewLayer
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        context.coordinator.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
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

    @State private var lastZoomFactor: CGFloat = 1.0

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

            // カメラズームコントロール
            if !isTheaterMode {
                VStack(spacing: 12) {
                    // ズームイン
                    Button(action: {
                        zoomIn()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 44, height: 44)

                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("ズームイン")
                    .accessibilityHint("カメラを1.5倍拡大します")

                    // ズームアウト
                    Button(action: {
                        zoomOut()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 44, height: 44)

                            Image(systemName: "minus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("ズームアウト")
                    .accessibilityHint("カメラを縮小します")

                    // リセットボタン
                    Button(action: {
                        cameraManager.zoom(factor: 1.0)
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
}
