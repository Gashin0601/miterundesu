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
    @Published var isCapturing = false // 撮影処理中フラグ

    var maxZoomFactor: CGFloat = 100.0 // デフォルト最大拡大率

    let session = AVCaptureSession() // internal に変更（CameraPreview から直接アクセス可能に）
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var device: AVCaptureDevice?
    private var customZoomSlider: Any? // iOS 18.0以降では AVCaptureSlider
    private var photoDelegates: [UUID: PhotoCaptureDelegate] = [:] // アクティブなデリゲートを管理

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

            // セッションプリセットを設定（.photoは4:3アスペクト比）
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

            // エラー -17281 でセッションが壊れている可能性があるため、常に startRunning を呼ぶ
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
                // セッションが開始されたらカメラ準備完了
                if self.session.isRunning {
                    self.isCameraReady = true
                    #if DEBUG
                    print("📷 Camera session started successfully")
                    #endif
                } else {
                    #if DEBUG
                    print("⚠️ Camera session failed to start!")
                    #endif
                }
            }
        }
    }

    // カメラセッション停止
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            // エラー -17281 でセッションが壊れている可能性があるため、常に stopRunning を呼ぶ
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
                self.isCameraReady = false
                #if DEBUG
                print("📷 Camera session stopped")
                #endif
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
                #if DEBUG
                print("Error zooming: \(error)")
                #endif
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
                #if DEBUG
                print("Error zooming: \(error)")
                #endif
            }
        }
    }

    // 写真をキャプチャ
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        // 既に撮影中の場合は処理しない
        guard !isCapturing else {
            #if DEBUG
            print("⚠️ 撮影処理中のため、新しい撮影をスキップします")
            #endif
            return
        }

        // 撮影開始
        DispatchQueue.main.async {
            self.isCapturing = true
            #if DEBUG
            print("📷 撮影開始 - isCapturing = true")
            #endif
        }

        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality

        // デリゲート用の一意のID
        let delegateId = UUID()

        let photoCaptureDelegate = PhotoCaptureDelegate(
            completion: { [weak self] image in
                guard let self = self else { return }

                // 撮影完了後にフラグを解除
                DispatchQueue.main.async {
                    self.isCapturing = false
                    #if DEBUG
                    print("📷 撮影完了 - isCapturing = false")
                    #endif
                }

                // 元のcompletionを呼び出す
                completion(image)
            },
            cleanup: { [weak self] in
                guard let self = self else { return }

                // デリゲートを辞書から削除（メモリ解放）
                self.sessionQueue.async {
                    self.photoDelegates.removeValue(forKey: delegateId)
                    #if DEBUG
                    print("🗑️ PhotoCaptureDelegate解放 - 残り: \(self.photoDelegates.count)")
                    #endif
                }
            }
        )

        // デリゲートを保持（キャプチャ完了まで）
        photoDelegates[delegateId] = photoCaptureDelegate
        #if DEBUG
        print("📷 PhotoCaptureDelegate追加 - 合計: \(photoDelegates.count)")
        #endif

        photoOutput.capturePhoto(with: settings, delegate: photoCaptureDelegate)
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
        #if DEBUG
        print("Camera Controls became active")
        #endif
    }

    @available(iOS 18.0, *)
    func sessionControlsWillEnterFullscreenAppearance(_ session: AVCaptureSession) {
        // Camera Controlがフルスクリーン表示になるとき
        #if DEBUG
        print("Camera Controls entering fullscreen")
        #endif
    }

    @available(iOS 18.0, *)
    func sessionControlsWillExitFullscreenAppearance(_ session: AVCaptureSession) {
        // Camera Controlがフルスクリーン表示から戻るとき
        #if DEBUG
        print("Camera Controls exiting fullscreen")
        #endif
    }

    @available(iOS 18.0, *)
    func sessionControlsDidBecomeInactive(_ session: AVCaptureSession) {
        // Camera Controlが非アクティブになったとき
        #if DEBUG
        print("Camera Controls became inactive")
        #endif
    }
}

// MARK: - Photo Capture Delegate
private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    private let cleanup: () -> Void

    init(completion: @escaping (UIImage?) -> Void, cleanup: @escaping () -> Void) {
        self.completion = completion
        self.cleanup = cleanup
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            // 処理完了後にクリーンアップ
            cleanup()
        }

        if let error = error {
            #if DEBUG
            print("Error capturing photo: \(error)")
            #endif
            completion(nil)
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            completion(nil)
            return
        }

        // メモリ効率的にダウンサンプリング（最大4096px）
        guard let downsampledImage = UIImage.downsample(imageData: imageData, maxDimension: 4096) else {
            completion(nil)
            return
        }

        // ウォーターマークを焼き込む
        let watermarkText = WatermarkHelper.generateWatermarkText()
        let watermarkedImage = downsampledImage.withWatermark(text: watermarkText, position: .bottomLeft)

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

// MARK: - UIImage Downsampling Extension
extension UIImage {
    /// メモリ効率的な画像ダウンサンプリング
    static func downsample(imageData: Data, maxDimension: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions) else {
            return nil
        }

        // 画像のプロパティを取得（メモリにロードせず）
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return nil
        }

        // 最大寸法を超えている場合のみダウンサンプリング
        let maxOriginalDimension = max(width, height)
        if maxOriginalDimension <= maxDimension {
            // 元のサイズが小さい場合はそのまま
            return UIImage(data: imageData)
        }

        // ダウンサンプリング倍率を計算
        let downsampleScale = maxDimension / maxOriginalDimension

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }

        #if DEBUG
        print("📸 画像をダウンサンプリング: \(Int(width))x\(Int(height)) -> \(Int(width * downsampleScale))x\(Int(height * downsampleScale))")
        #endif

        return UIImage(cgImage: downsampledImage)
    }
}
