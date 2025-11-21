//
//  PressModeManager.swift
//  miterundesu
//
//  Created by Claude Code
//  User ID + Password authentication for Press Mode
//

import Foundation
import UIKit
import Supabase
import CryptoKit

/// プレスモード管理クラス（User ID + Password認証）
@MainActor
class PressModeManager: ObservableObject {
    static let shared = PressModeManager()

    @Published var isPressModeEnabled: Bool = false
    @Published var pressAccount: PressAccount?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var isLoggedIn: Bool = false

    private let userIdKey = "miterundesu.press.userId"
    private let loginDateKey = "miterundesu.press.loginDate"

    // Keychain keys
    private let keychainService = "com.miterundesu.press"
    private let keychainUserIdKey = "userId"
    private let keychainPasswordKey = "password"

    private init() {
        // アプリ起動時に保存された認証情報で自動ログイン試行
        Task {
            await checkSavedCredentials()
        }
    }

    // MARK: - Login & Logout

    /// ログイン処理
    func login(userId: String, password: String) async -> Bool {
        isLoading = true
        error = nil

        do {
            // 1. Supabase RPC関数でパスワード検証付きアカウント取得
            let response: [PressAccount] = try await supabase
                .rpc("verify_press_account_password", params: [
                    "p_user_id": userId,
                    "p_password": password
                ])
                .execute()
                .value

            // 2. 認証失敗チェック（パスワードが間違っている場合は空配列が返る）
            guard let account = response.first else {
                error = "ユーザーIDまたはパスワードが正しくありません"
                isLoading = false
                #if DEBUG
                print("❌ 認証失敗: ユーザーIDまたはパスワードが間違っています")
                #endif
                return false
            }

            // 3. アカウント状態を確認
            guard account.isValid else {
                switch account.status {
                case .expired:
                    error = "アカウントの有効期限が切れています"
                case .deactivated:
                    error = "このアカウントは無効化されています"
                default:
                    error = "アカウントが無効です"
                }
                isLoading = false
                return false
            }

            // 4. ログイン成功
            pressAccount = account
            isPressModeEnabled = true
            isLoggedIn = true

            // 認証情報を保存
            saveCredentials(userId: userId, password: password)
            recordLogin()

            // 最終ログイン日時を更新（Supabase）
            await updateLastLoginDate(userId: userId)

            #if DEBUG
            print("✅ ログイン成功: \(account.organizationName) (\(userId))")
            print("   有効期限: \(account.expirationDisplayString)")
            print("   残り日数: \(account.daysUntilExpiration)日")
            #endif

            isLoading = false
            return true

        } catch {
            self.error = "ログインに失敗しました: \(error.localizedDescription)"
            isLoading = false
            #if DEBUG
            print("❌ ログインエラー: \(error)")
            #endif
            return false
        }
    }

    /// ログアウト処理
    func logout() {
        isPressModeEnabled = false
        isLoggedIn = false
        pressAccount = nil
        error = nil

        // 認証情報をクリア
        clearCredentials()
        clearLoginRecord()

        #if DEBUG
        print("🚪 ログアウト")
        #endif
    }

    /// 保存された認証情報で自動ログイン試行
    private func checkSavedCredentials() async {
        guard let userId = loadUserId(),
              let password = loadPassword() else {
            #if DEBUG
            print("ℹ️ 保存された認証情報なし")
            #endif
            return
        }

        #if DEBUG
        print("🔄 保存された認証情報で自動ログイン試行: \(userId)")
        #endif

        let success = await login(userId: userId, password: password)
        if !success {
            // 自動ログイン失敗時は認証情報をクリア
            clearCredentials()
            #if DEBUG
            print("⚠️ 自動ログイン失敗")
            #endif
        }
    }

    // MARK: - Keychain Operations

    /// 認証情報をKeychainに保存
    private func saveCredentials(userId: String, password: String) {
        saveToKeychain(key: keychainUserIdKey, value: userId)
        saveToKeychain(key: keychainPasswordKey, value: password)

        #if DEBUG
        print("🔐 認証情報をKeychainに保存")
        #endif
    }

    /// UserIDをKeychainから読み込み
    private func loadUserId() -> String? {
        return loadFromKeychain(key: keychainUserIdKey)
    }

    /// PasswordをKeychainから読み込み
    private func loadPassword() -> String? {
        return loadFromKeychain(key: keychainPasswordKey)
    }

    /// 認証情報をKeychainからクリア
    private func clearCredentials() {
        deleteFromKeychain(key: keychainUserIdKey)
        deleteFromKeychain(key: keychainPasswordKey)

        #if DEBUG
        print("🗑️ 認証情報をクリア")
        #endif
    }

    /// Keychainに保存
    private func saveToKeychain(key: String, value: String) {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // 既存のアイテムを削除
        SecItemDelete(query as CFDictionary)

        // 新しいアイテムを追加
        let status = SecItemAdd(query as CFDictionary, nil)

        #if DEBUG
        if status != errSecSuccess {
            print("⚠️ Keychain保存エラー (\(key)): \(status)")
        }
        #endif
    }

    /// Keychainから読み込み
    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    /// Keychainから削除
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Login Record

    /// ログイン成功を記録
    private func recordLogin() {
        UserDefaults.standard.set(Date(), forKey: loginDateKey)
    }

    /// ログイン記録をクリア
    private func clearLoginRecord() {
        UserDefaults.standard.removeObject(forKey: loginDateKey)
    }

    /// 最終ログイン日時をSupabaseに更新
    private func updateLastLoginDate(userId: String) async {
        do {
            let _: [PressAccount] = try await supabase
                .from("press_accounts")
                .update(["last_login_at": ISO8601DateFormatter().string(from: Date())])
                .eq("user_id", value: userId)
                .execute()
                .value

            #if DEBUG
            print("✅ 最終ログイン日時を更新")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ 最終ログイン日時の更新失敗: \(error)")
            #endif
        }
    }

    // MARK: - Account Info

    /// ログイン中のユーザーIDを取得
    func getCurrentUserId() -> String? {
        return pressAccount?.userId
    }

    /// アカウント情報の概要を取得
    func getAccountSummary() -> String? {
        return pressAccount?.summary
    }

    /// 有効期限までの残り日数を取得
    func getDaysUntilExpiration() -> Int? {
        return pressAccount?.daysUntilExpiration
    }
}
