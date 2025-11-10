//
//  CameraManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import AVFoundation
import SwiftUI
import Combine

class CameraManager: NSObject, ObservableObject, AVCaptureSessionControlsDelegate {
    @Published var currentZoom: CGFloat = 1.0
    @Published var isSessionRunning = false
    @Published var isCameraReady = false
    @Published var error: CameraError?

    var maxZoomFactor: CGFloat = 100.0 // デフォルト最大拡大率

    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var device: AVCaptureDevice?
    private var customZoomSlider: AVCaptureSlider?

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    // プレビューレイヤーを保持（毎回新しく作成しない）
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

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

                // Camera Control用のカスタムズームスライダーを追加
                if #available(iOS 18.0, *) {
                    // 既存のコントロールを削除
                    self.session.controls.forEach { self.session.removeControl($0) }

                    // デバイスの最大ズーム倍率を取得
                    let deviceMaxZoom = camera.activeFormat.videoMaxZoomFactor
                    let clampedMaxZoom = min(deviceMaxZoom, self.maxZoomFactor)

                    // カスタムズームスライダーを作成（1倍から設定された最大倍率まで）
                    let zoomSlider = AVCaptureSlider(
                        "Zoom",
                        symbolName: "plus.magnifyingglass",
                        in: 1.0...Float(clampedMaxZoom)
                    )

                    // スライダーのアクションを設定
                    zoomSlider.setActionQueue(self.sessionQueue) { [weak self] zoomValue in
                        guard let self = self else { return }

                        // スライダーの値をそのまま使用（速度計算を削除）
                        let targetZoom = CGFloat(zoomValue)
                        let finalZoom = min(max(targetZoom, 1.0), min(self.maxZoomFactor, CGFloat(clampedMaxZoom)))

                        // ズームを適用
                        DispatchQueue.main.async {
                            self.zoom(factor: finalZoom)
                        }
                    }

                    self.customZoomSlider = zoomSlider

                    // セッションにコントロールを追加
                    if self.session.canAddControl(zoomSlider) {
                        self.session.addControl(zoomSlider)
                    }

                    // セッションデリゲートを設定
                    self.session.setControlsDelegate(self, queue: self.sessionQueue)
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
                    // セッションが開始されたらカメラ準備完了
                    if self.session.isRunning {
                        self.isCameraReady = true
                    }
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
                    self.isCameraReady = false
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

                device.unlockForConfiguration()

                DispatchQueue.main.async {
                    self.currentZoom = clampedZoom
                }
            } catch {
                print("Error zooming: \(error)")
            }
        }
    }

    // スムーズなズーム処理（アニメーション付き）
    func smoothZoom(to factor: CGFloat, duration: Float = 0.5) {
        guard let device = device else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                // ズーム倍率を制限
                let clampedZoom = min(max(factor, 1.0), min(device.activeFormat.videoMaxZoomFactor, self.maxZoomFactor))

                // レート（ズーム速度）を計算: 距離 / 時間
                let currentZoom = device.videoZoomFactor
                let distance = abs(clampedZoom - currentZoom)
                let rate = distance / CGFloat(duration)

                // rampメソッドでスムーズにズーム
                device.ramp(toVideoZoomFactor: clampedZoom, withRate: Float(rate))

                device.unlockForConfiguration()

                // アニメーション中も現在のズーム値を更新するためのタイマー（メインスレッドで作成）
                DispatchQueue.main.async {
                    let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                        self.currentZoom = device.videoZoomFactor

                        // 目標値に到達したらタイマーを停止
                        if abs(device.videoZoomFactor - clampedZoom) < 0.01 {
                            timer.invalidate()
                            self.currentZoom = clampedZoom
                        }
                    }
                    RunLoop.main.add(timer, forMode: .common)
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

        // Camera Controlのズームスライダーも更新
        if #available(iOS 18.0, *) {
            sessionQueue.async { [weak self] in
                guard let self = self, let camera = self.device else { return }

                // 既存のコントロールを削除
                self.session.controls.forEach { self.session.removeControl($0) }

                // 新しい範囲でズームスライダーを再作成
                let deviceMaxZoom = camera.activeFormat.videoMaxZoomFactor
                let clampedMaxZoom = min(deviceMaxZoom, factor)

                let zoomSlider = AVCaptureSlider(
                    "Zoom",
                    symbolName: "plus.magnifyingglass",
                    in: 1.0...Float(clampedMaxZoom)
                )

                zoomSlider.setActionQueue(self.sessionQueue) { [weak self] zoomValue in
                    guard let self = self else { return }

                    // スライダーの値をそのまま使用
                    let targetZoom = CGFloat(zoomValue)
                    let finalZoom = min(max(targetZoom, 1.0), min(self.maxZoomFactor, clampedMaxZoom))

                    DispatchQueue.main.async {
                        self.zoom(factor: finalZoom)
                    }
                }

                self.customZoomSlider = zoomSlider

                if self.session.canAddControl(zoomSlider) {
                    self.session.addControl(zoomSlider)
                }
            }
        }
    }

    // MARK: - AVCaptureSessionControlsDelegate
    @available(iOS 18.0, *)
    func sessionControlsDidBecomeActive(_ session: AVCaptureSession) {
        // Camera Controlがアクティブになったとき
        print("Camera Controls became active")
    }

    @available(iOS 18.0, *)
    func sessionControlsWillEnterFullscreenAppearance(_ session: AVCaptureSession) {
        // Camera Controlがフルスクリーン表示になるとき
        print("Camera Controls entering fullscreen")
    }

    @available(iOS 18.0, *)
    func sessionControlsWillExitFullscreenAppearance(_ session: AVCaptureSession) {
        // Camera Controlがフルスクリーン表示から戻るとき
        print("Camera Controls exiting fullscreen")
    }

    @available(iOS 18.0, *)
    func sessionControlsDidBecomeInactive(_ session: AVCaptureSession) {
        // Camera Controlが非アクティブになったとき
        print("Camera Controls became inactive")
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

        // ウォーターマークを焼き込む
        let watermarkText = WatermarkHelper.generateWatermarkText()
        let watermarkedImage = image.withWatermark(text: watermarkText, position: .bottomLeft)

        completion(watermarkedImage)
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
