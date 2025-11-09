//
//  ImageManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import Combine

// MARK: - Image Metadata (for persistence)
struct ImageMetadata: Codable {
    let id: UUID
    let capturedAt: Date
    let expiresAt: Date
}

// MARK: - Captured Image Model
struct CapturedImage: Identifiable {
    let id: UUID
    let capturedAt: Date
    let expiresAt: Date

    var image: UIImage {
        loadImage() ?? UIImage()
    }

    var remainingTime: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }

    var isExpired: Bool {
        Date() >= expiresAt
    }

    init(image: UIImage, id: UUID = UUID(), capturedAt: Date = Date(), shouldSave: Bool = true) {
        self.id = id
        self.capturedAt = capturedAt
        self.expiresAt = capturedAt.addingTimeInterval(600) // 10分後
        if shouldSave {
            saveImage(image)
        }
    }

    // 画像をファイルシステムに保存
    private func saveImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let fileURL = getImageFileURL()
        try? imageData.write(to: fileURL)
    }

    // 画像をファイルシステムから読み込み
    func loadImage() -> UIImage? {
        let fileURL = getImageFileURL()
        guard let imageData = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: imageData)
    }

    // 画像ファイルのURLを取得
    private func getImageFileURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("\(id.uuidString).jpg")
    }

    // 画像ファイルを削除
    func deleteImageFile() {
        let fileURL = getImageFileURL()
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - Image Manager
class ImageManager: ObservableObject {
    @Published var capturedImages: [CapturedImage] = []

    private var timers: [UUID: Timer] = [:]
    private let metadataKey = "capturedImagesMetadata"

    init() {
        loadImages()
    }

    // アプリ起動時に画像を読み込み
    private func loadImages() {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let metadata = try? JSONDecoder().decode([ImageMetadata].self, from: data) else {
            return
        }

        // 期限切れでない画像のみ復元
        for meta in metadata {
            if meta.expiresAt > Date() {
                // メタデータから画像を復元（ダミー画像で初期化、保存はしない）
                let dummyImage = UIImage()
                let capturedImage = CapturedImage(
                    image: dummyImage,
                    id: meta.id,
                    capturedAt: meta.capturedAt,
                    shouldSave: false
                )

                // 画像ファイルが存在するか確認
                if capturedImage.loadImage() != nil {
                    capturedImages.append(capturedImage)

                    // 残り時間でタイマーを設定
                    let remainingTime = max(capturedImage.remainingTime, 0)
                    if remainingTime > 0 {
                        let timer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
                            self?.removeImage(capturedImage.id)
                        }
                        timers[capturedImage.id] = timer
                    } else {
                        // 既に期限切れなら即座に削除
                        capturedImage.deleteImageFile()
                    }
                } else {
                    print("⚠️ 画像ファイルが見つかりません: \(meta.id)")
                }
            } else {
                // 期限切れの画像ファイルを削除
                let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("\(meta.id.uuidString).jpg")
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        // 画像を撮影時刻順にソート（最新が先頭）
        capturedImages.sort { $0.capturedAt > $1.capturedAt }

        // メタデータを更新（期限切れを除外）
        saveMetadata()
    }

    // メタデータを保存
    private func saveMetadata() {
        let metadata = capturedImages.map { ImageMetadata(id: $0.id, capturedAt: $0.capturedAt, expiresAt: $0.expiresAt) }
        if let data = try? JSONEncoder().encode(metadata) {
            UserDefaults.standard.set(data, forKey: metadataKey)
        }
    }

    // 画像を追加
    func addImage(_ image: UIImage) {
        let capturedImage = CapturedImage(image: image)
        capturedImages.insert(capturedImage, at: 0) // 最新を先頭に

        // メタデータを保存
        saveMetadata()

        // 10分後に自動削除するタイマーを設定
        let timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: false) { [weak self] _ in
            self?.removeImage(capturedImage.id)
        }
        timers[capturedImage.id] = timer
    }

    // 画像を削除
    func removeImage(_ id: UUID) {
        if let index = capturedImages.firstIndex(where: { $0.id == id }) {
            let capturedImage = capturedImages[index]
            capturedImage.deleteImageFile() // ファイルを削除
            capturedImages.remove(at: index)
        }

        // タイマーを停止
        timers[id]?.invalidate()
        timers.removeValue(forKey: id)

        // メタデータを更新
        saveMetadata()
    }

    // 期限切れの画像をすべて削除
    func removeExpiredImages() {
        let expiredIds = capturedImages.filter { $0.isExpired }.map { $0.id }
        expiredIds.forEach { removeImage($0) }
    }

    // すべての画像を削除
    func clearAllImages() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()

        // すべてのファイルを削除
        capturedImages.forEach { $0.deleteImageFile() }
        capturedImages.removeAll()

        // メタデータをクリア
        UserDefaults.standard.removeObject(forKey: metadataKey)
    }

    deinit {
        // アプリ終了時はタイマーのみ停止（画像とメタデータは保持）
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
    }
}
