//
//  CoreDataManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import CoreData
import UIKit

// MARK: - Core Data Manager
class CoreDataManager {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        // プログラマティックにモデルを定義
        let model = NSManagedObjectModel()

        // CapturedImageEntity の定義
        let imageEntity = NSEntityDescription()
        imageEntity.name = "CapturedImageEntity"
        imageEntity.managedObjectClassName = NSStringFromClass(CapturedImageEntity.self)

        // 属性の定義
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let imageDataAttribute = NSAttributeDescription()
        imageDataAttribute.name = "imageData"
        imageDataAttribute.attributeType = .binaryDataAttributeType
        imageDataAttribute.isOptional = false
        imageDataAttribute.allowsExternalBinaryDataStorage = true

        let capturedAtAttribute = NSAttributeDescription()
        capturedAtAttribute.name = "capturedAt"
        capturedAtAttribute.attributeType = .dateAttributeType
        capturedAtAttribute.isOptional = false

        let expirationDateAttribute = NSAttributeDescription()
        expirationDateAttribute.name = "expirationDate"
        expirationDateAttribute.attributeType = .dateAttributeType
        expirationDateAttribute.isOptional = false

        imageEntity.properties = [idAttribute, imageDataAttribute, capturedAtAttribute, expirationDateAttribute]

        model.entities = [imageEntity]

        let container = NSPersistentContainer(name: "miterundesu", managedObjectModel: model)
        container.loadPersistentStores { description, error in
            if let error = error {
                // エラーハンドリング: ストアのロードに失敗した場合でもアプリを続行
                // 画像の永続化はできないが、アプリの基本機能（カメラ、拡大）は動作する
                #if DEBUG
                print("⚠️ CoreData: ストアのロードに失敗しました: \(error)")
                print("⚠️ CoreData: 画像の保存機能は無効化されますが、アプリは動作します")
                #endif
                // エラーを記録（将来的にクラッシュレポートサービスに送信可能）
                NSLog("CoreData store failed to load: \(error.localizedDescription)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                #if DEBUG
                print("Error saving context: \(error)")
                #endif
            }
        }
    }
}

// MARK: - Captured Image Entity
@objc(CapturedImageEntity)
class CapturedImageEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageData: Data
    @NSManaged var capturedAt: Date
    @NSManaged var expirationDate: Date
}
