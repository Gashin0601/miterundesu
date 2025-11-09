//
//  CameraManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import AVFoundation
import SwiftUI
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var currentZoom: CGFloat = 1.0
    @Published var isSessionRunning = false
    @Published var error: CameraError?

    var maxZoomFactor: CGFloat = 100.0 // デフォルト最大拡大率

    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var device: AVCaptureDevice?

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    var previewLayer: AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    override init() {
        super.init()
    }

    // カメラのセットアップ
    func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()

            // セッションプリセットを設定
            if self.session.canSetSessionPreset(.photo) {
                self.session.sessionPreset = .photo
            }

            // カメラデバイスの取得
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async {
                    self.error = .cameraUnavailable
                }
                self.session.commitConfiguration()
                return
            }

            self.device = camera

            do {
                // カメラ入力を作成
                let input = try AVCaptureDeviceInput(device: camera)

                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.videoDeviceInput = input
                }

                // ビデオ出力を追加
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                }

                // 写真出力を追加
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                }

                self.session.commitConfiguration()

            } catch {
                DispatchQueue.main.async {
                    self.error = .cannotAddInput
                }
                self.session.commitConfiguration()
                return
            }
        }
    }

    // カメラセッション開始
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }

    // カメラセッション停止
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }

    // ズーム処理
    func zoom(factor: CGFloat) {
        guard let device = device else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                // ズーム倍率を制限
                let clampedZoom = min(max(factor, 1.0), min(device.activeFormat.videoMaxZoomFactor, self.maxZoomFactor))
                device.videoZoomFactor = clampedZoom

                try device.unlockForConfiguration()

                DispatchQueue.main.async {
                    self.currentZoom = clampedZoom
                }
            } catch {
                print("Error zooming: \(error)")
            }
        }
    }

    // 写真をキャプチャ
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality

        let photoCaptureDelegate = PhotoCaptureDelegate(completion: completion)
        photoOutput.capturePhoto(with: settings, delegate: photoCaptureDelegate)

        // デリゲートを保持（キャプチャ完了まで）
        objc_setAssociatedObject(self, "photoCaptureDelegate_\(UUID().uuidString)", photoCaptureDelegate, .OBJC_ASSOCIATION_RETAIN)
    }

    // 最大ズーム倍率を設定
    func setMaxZoomFactor(_ factor: CGFloat) {
        maxZoomFactor = factor
    }
}

// MARK: - Photo Capture Delegate
private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            completion(nil)
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(nil)
            return
        }

        completion(image)
    }
}

// MARK: - Camera Error
enum CameraError: Error, LocalizedError {
    case cameraUnavailable
    case cannotAddInput
    case cannotCapturePhoto

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "カメラが利用できません"
        case .cannotAddInput:
            return "カメラ入力を追加できません"
        case .cannotCapturePhoto:
            return "写真をキャプチャできません"
        }
    }
}
