//
//  PressDevice.swift
//  miterundesu
//
//  Created by Claude Code
//

import Foundation

/// プレスデバイスの期限状態
enum PressDeviceStatus {
    case notStarted      // まだ開始前
    case active          // 有効期間内
    case expired         // 期限切れ
    case deactivated     // 無効化されている
}

/// プレスデバイス情報のモデル
struct PressDevice: Codable, Identifiable {
    let id: UUID
    let deviceId: String
    let accessCode: String
    let organization: String
    let contactEmail: String?
    let contactName: String?
    let startsAt: Date
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
        case startsAt = "starts_at"
        case expiresAt = "expires_at"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case notes
    }

    /// 期限状態を判定
    var status: PressDeviceStatus {
        let now = Date()

        if !isActive {
            return .deactivated
        }

        if now < startsAt {
            return .notStarted
        }

        if now > expiresAt {
            return .expired
        }

        return .active
    }

    /// プレスモードが有効かどうかを判定
    var isValid: Bool {
        return status == .active
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

    /// 開始日の表示用文字列（日本語）
    var startDisplayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: startsAt)
    }

    /// 有効期限の表示用文字列（日本語）
    var expirationDisplayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: expiresAt)
    }

    /// 期間の表示用文字列（日本語）
    var periodDisplayString: String {
        return "\(startDisplayString) 〜 \(expirationDisplayString)"
    }

    /// 状態に応じたメッセージ
    var statusMessage: String {
        switch status {
        case .notStarted:
            return "プレスモードはまだ開始されていません。\n利用期間: \(periodDisplayString)"
        case .active:
            return "プレスモードは有効です。"
        case .expired:
            return "プレスモードの有効期限が切れています。\n必要な場合は再申請してください。\n利用期間: \(periodDisplayString)"
        case .deactivated:
            return "このデバイスのプレスモードは無効化されています。"
        }
    }
}
