//
//  ImageManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import Combine

// MARK: - Captured Image Model
struct CapturedImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let capturedAt: Date
    let expiresAt: Date

    var remainingTime: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }

    var isExpired: Bool {
        Date() >= expiresAt
    }

    init(image: UIImage) {
        self.image = image
        self.capturedAt = Date()
        self.expiresAt = Date().addingTimeInterval(600) // 10分後
    }
}

// MARK: - Image Manager
class ImageManager: ObservableObject {
    @Published var capturedImages: [CapturedImage] = []

    private var timers: [UUID: Timer] = [:]

    // 画像を追加
    func addImage(_ image: UIImage) {
        let capturedImage = CapturedImage(image: image)
        capturedImages.insert(capturedImage, at: 0) // 最新を先頭に

        // 10分後に自動削除するタイマーを設定
        let timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: false) { [weak self] _ in
            self?.removeImage(capturedImage.id)
        }
        timers[capturedImage.id] = timer
    }

    // 画像を削除
    func removeImage(_ id: UUID) {
        if let index = capturedImages.firstIndex(where: { $0.id == id }) {
            capturedImages.remove(at: index)
        }

        // タイマーを停止
        timers[id]?.invalidate()
        timers.removeValue(forKey: id)
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
        capturedImages.removeAll()
    }

    deinit {
        clearAllImages()
    }
}
