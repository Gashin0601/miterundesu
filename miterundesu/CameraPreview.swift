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
            .cornerRadius(20)
    }
}
