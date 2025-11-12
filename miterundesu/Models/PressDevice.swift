//
//  PressDevice.swift
//  miterundesu
//
//  Created by Claude Code
//

import Foundation

/// プレスデバイス情報のモデル
struct PressDevice: Codable, Identifiable {
    let id: UUID
    let deviceId: String
    let accessCode: String
    let organization: String
    let contactEmail: String?
    let contactName: String?
    let expiresAt: Date
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case accessCode = "access_code"
        case organization
        case contactEmail = "contact_email"
        case contactName = "contact_name"
        case expiresAt = "expires_at"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case notes
    }

    /// プレスモードが有効かどうかを判定
    var isValid: Bool {
        return isActive && expiresAt > Date()
    }

    /// 有効期限までの残り日数
    var daysUntilExpiration: Int {
        let calendar = Calendar.current
        let now = Date()
        if let days = calendar.dateComponents([.day], from: now, to: expiresAt).day {
            return max(0, days)
        }
        return 0
    }

    /// 有効期限の表示用文字列（日本語）
    var expirationDisplayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: expiresAt)
    }
}
