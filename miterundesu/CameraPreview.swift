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

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = cameraManager.previewLayer.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // 特に何もしない - PreviewViewが自動的にフレームを管理
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

        }
        .cornerRadius(20)
    }

}
