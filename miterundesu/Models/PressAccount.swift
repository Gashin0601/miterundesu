//
//  PressAccount.swift
//  miterundesu
//
//  Created by Claude Code
//  User ID + Password authentication for Press Mode
//

import Foundation

/// プレスアカウントの状態
enum PressAccountStatus {
    case active          // 有効期間内
    case expired         // 期限切れ
    case deactivated     // 無効化されている
}

/// プレスアカウント情報のモデル（User ID + Password認証）
struct PressAccount: Codable, Identifiable {
    let id: UUID
    let userId: String
    let organizationName: String
    let organizationType: String?
    let contactPerson: String?
    let email: String?
    let phone: String?
    let approvedBy: String?
    let approvedAt: Date?
    let expiresAt: Date
    let isActive: Bool
    let lastLoginAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case organizationName = "organization_name"
        case organizationType = "organization_type"
        case contactPerson = "contact_person"
        case email
        case phone
        case approvedBy = "approved_by"
        case approvedAt = "approved_at"
        case expiresAt = "expires_at"
        case isActive = "is_active"
        case lastLoginAt = "last_login_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// アカウント状態を判定
    var status: PressAccountStatus {
        let now = Date()

        if !isActive {
            return .deactivated
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

    /// 有効期限の表示用文字列（日本語）
    var expirationDisplayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: expiresAt)
    }

    /// 承認日時の表示用文字列（日本語）
    var approvalDisplayString: String? {
        guard let approvedAt = approvedAt else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: approvedAt)
    }

    /// 最終ログイン日時の表示用文字列（日本語）
    var lastLoginDisplayString: String? {
        guard let lastLoginAt = lastLoginAt else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: lastLoginAt)
    }

    /// 状態に応じたメッセージ
    var statusMessage: String {
        switch status {
        case .active:
            let daysLeft = daysUntilExpiration
            if daysLeft <= 7 {
                return "プレスモードは有効です（残り\(daysLeft)日）"
            } else {
                return "プレスモードは有効です"
            }
        case .expired:
            return "プレスモードの有効期限が切れています。\n必要な場合は再申請してください。\n有効期限: \(expirationDisplayString)"
        case .deactivated:
            return "このアカウントのプレスモードは無効化されています。"
        }
    }

    /// アカウント情報の概要
    var summary: String {
        var info = "組織: \(organizationName)"
        if let contact = contactPerson {
            info += "\n担当者: \(contact)"
        }
        info += "\n有効期限: \(expirationDisplayString)"
        if let lastLogin = lastLoginDisplayString {
            info += "\n最終ログイン: \(lastLogin)"
        }
        return info
    }
}

/// ログインレスポンス用の構造体
struct PressLoginResponse: Codable {
    let account: PressAccount
    let success: Bool
    let message: String?
}
