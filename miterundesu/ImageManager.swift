//
//  ImageManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import Combine
import CoreData

// MARK: - Captured Image Model
struct CapturedImage: Identifiable {
    let id: UUID
    let capturedAt: Date
    let expiresAt: Date
    private let imageData: Data

    var image: UIImage {
        UIImage(data: imageData) ?? UIImage()
    }

    var remainingTime: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }

    var isExpired: Bool {
        Date() >= expiresAt
    }

    init(image: UIImage, id: UUID = UUID(), capturedAt: Date = Date()) {
        self.id = id
        self.capturedAt = capturedAt
        self.expiresAt = capturedAt.addingTimeInterval(600) // 10分後
        self.imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    // CoreDataから復元
    init(entity: CapturedImageEntity) {
        self.id = entity.id
        self.capturedAt = entity.capturedAt
        self.expiresAt = entity.expirationDate
        self.imageData = entity.imageData
    }
}

// MARK: - Image Manager
class ImageManager: ObservableObject {
    @Published var capturedImages: [CapturedImage] = []

    private var timers: [UUID: Timer] = [:]
    private let context = CoreDataManager.shared.context

    init() {
        loadImages()
    }

    // アプリ起動時にCoreDataから画像を読み込み
    private func loadImages() {
        let fetchRequest: NSFetchRequest<CapturedImageEntity> = NSFetchRequest(entityName: "CapturedImageEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "capturedAt", ascending: false)]

        do {
            let entities = try context.fetch(fetchRequest)

            for entity in entities {
                let capturedImage = CapturedImage(entity: entity)

                // 期限切れチェック
                if !capturedImage.isExpired {
                    capturedImages.append(capturedImage)

                    // 残り時間でタイマーを設定
                    let remainingTime = max(capturedImage.remainingTime, 0)
                    if remainingTime > 0 {
                        let timer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
                            self?.removeImage(capturedImage.id)
                        }
                        timers[capturedImage.id] = timer
                    }
                } else {
                    // 期限切れの画像をCoreDataから削除
                    context.delete(entity)
                }
            }

            // 変更を保存
            CoreDataManager.shared.saveContext()
        } catch {
            print("Error loading images from CoreData: \(error)")
        }
    }

    // 画像を追加
    func addImage(_ image: UIImage) {
        let capturedImage = CapturedImage(image: image)
        capturedImages.insert(capturedImage, at: 0) // 最新を先頭に

        // CoreDataに保存
        let entity = CapturedImageEntity(context: context)
        entity.id = capturedImage.id
        entity.imageData = capturedImage.image.jpegData(compressionQuality: 0.8) ?? Data()
        entity.capturedAt = capturedImage.capturedAt
        entity.expirationDate = capturedImage.expiresAt

        CoreDataManager.shared.saveContext()

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

        // CoreDataから削除
        let fetchRequest: NSFetchRequest<CapturedImageEntity> = NSFetchRequest(entityName: "CapturedImageEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let entities = try context.fetch(fetchRequest)
            entities.forEach { context.delete($0) }
            CoreDataManager.shared.saveContext()
        } catch {
            print("Error deleting image from CoreData: \(error)")
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

        // CoreDataからすべて削除
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CapturedImageEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            CoreDataManager.shared.saveContext()
        } catch {
            print("Error clearing all images from CoreData: \(error)")
        }
    }

    deinit {
        // アプリ終了時はタイマーのみ停止（CoreDataのデータは保持）
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
    }
}
