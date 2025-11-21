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

    // 画像をオンデマンドでデコード（メモリ効率化）
    var image: UIImage {
        // キャッシュをチェック
        if let cached = ImageCache.shared.get(id) {
            return cached
        }

        // データからデコードしてキャッシュに追加（autoreleasepoolで一時オブジェクトを即解放）
        return autoreleasepool {
            if let decoded = UIImage(data: imageData) {
                ImageCache.shared.set(decoded, forKey: id)
                return decoded
            }
            return UIImage()
        }
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

        // 画像を0.6品質でJPEG圧縮して保存（メモリ節約）
        self.imageData = image.jpegData(compressionQuality: 0.6) ?? Data()

        // 最初の画像はキャッシュに追加
        if let optimizedImage = UIImage(data: self.imageData) {
            ImageCache.shared.set(optimizedImage, forKey: id)
        }
    }

    // CoreDataから復元
    init(entity: CapturedImageEntity) {
        self.id = entity.id
        self.capturedAt = entity.capturedAt
        self.expiresAt = entity.expirationDate
        self.imageData = entity.imageData
    }
}

// MARK: - Image Cache (LRU)
class ImageCache {
    static let shared = ImageCache()

    private var cache: [UUID: UIImage] = [:]
    private var accessOrder: [UUID] = []
    private let maxCacheSize = 2 // 最大2枚までキャッシュ（メモリ節約）
    private let queue = DispatchQueue(label: "com.miterundesu.imagecache", attributes: .concurrent)

    init() {
        // メモリ警告時にキャッシュをクリア
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            #if DEBUG
            print("⚠️ メモリ警告 - 画像キャッシュをクリア")
            #endif
            self?.clear()
        }
    }

    func get(_ key: UUID) -> UIImage? {
        queue.sync {
            if let image = cache[key] {
                // アクセス順を更新
                updateAccessOrder(key)
                return image
            }
            return nil
        }
    }

    func set(_ image: UIImage, forKey key: UUID) {
        queue.async(flags: .barrier) {
            // 既存のエントリがあれば更新
            if self.cache[key] != nil {
                self.updateAccessOrder(key)
            } else {
                // 新規追加
                self.cache[key] = image
                self.accessOrder.append(key)

                // キャッシュサイズ超過時は古いものを削除
                if self.accessOrder.count > self.maxCacheSize {
                    let oldestKey = self.accessOrder.removeFirst()
                    self.cache.removeValue(forKey: oldestKey)
                    #if DEBUG
                    print("🗑️ 画像キャッシュから削除: \(oldestKey)")
                    #endif
                }
            }
        }
    }

    func remove(_ key: UUID) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
            self.accessOrder.removeAll { $0 == key }
        }
    }

    func clear() {
        queue.async(flags: .barrier) {
            let count = self.cache.count
            self.cache.removeAll()
            self.accessOrder.removeAll()
            #if DEBUG
            print("🗑️ 画像キャッシュをクリア (\(count)枚)")
            #endif
        }
    }

    private func updateAccessOrder(_ key: UUID) {
        if let index = self.accessOrder.firstIndex(of: key) {
            self.accessOrder.remove(at: index)
            self.accessOrder.append(key)
        }
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
            #if DEBUG
            print("Error loading images from CoreData: \(error)")
            #endif
        }
    }

    // 画像を追加
    func addImage(_ image: UIImage) {
        let capturedImage = CapturedImage(image: image)
        capturedImages.insert(capturedImage, at: 0) // 最新を先頭に

        // CoreDataに保存
        let entity = CapturedImageEntity(context: context)
        entity.id = capturedImage.id
        entity.imageData = capturedImage.image.jpegData(compressionQuality: 0.6) ?? Data()
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

        // キャッシュから削除
        ImageCache.shared.remove(id)

        // CoreDataから削除
        let fetchRequest: NSFetchRequest<CapturedImageEntity> = NSFetchRequest(entityName: "CapturedImageEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let entities = try context.fetch(fetchRequest)
            entities.forEach { context.delete($0) }
            CoreDataManager.shared.saveContext()
        } catch {
            #if DEBUG
            print("Error deleting image from CoreData: \(error)")
            #endif
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

        // キャッシュをクリア
        ImageCache.shared.clear()

        // CoreDataからすべて削除
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CapturedImageEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            CoreDataManager.shared.saveContext()
        } catch {
            #if DEBUG
            print("Error clearing all images from CoreData: \(error)")
            #endif
        }
    }

    deinit {
        // アプリ終了時はタイマーのみ停止（CoreDataのデータは保持）
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
    }
}
