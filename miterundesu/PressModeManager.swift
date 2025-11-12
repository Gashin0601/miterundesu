//
//  PressModeManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import Foundation
import UIKit
import Supabase

/// プレスモード管理クラス
@MainActor
class PressModeManager: ObservableObject {
    static let shared = PressModeManager()

    @Published var isPressModeEnabled: Bool = false
    @Published var pressDevice: PressDevice?
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let deviceIdKey = "miterundesu.deviceId"

    private init() {}

    /// デバイスIDを取得（永続化されたUUIDまたは新規生成）
    func getDeviceId() -> String {
        // Keychainに保存されたデバイスIDを取得
        if let savedId = UserDefaults.standard.string(forKey: deviceIdKey) {
            return savedId
        }

        // 新規生成（identifierForVendorを優先）
        let newId: String
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
            newId = vendorId
        } else {
            // identifierForVendorが取得できない場合は独自のUUIDを生成
            newId = UUID().uuidString
        }

        // 保存
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }

    /// プレスモード権限をチェック
    func checkPressModePermission() async {
        isLoading = true
        error = nil

        do {
            let deviceId = getDeviceId()

            // Supabaseからデバイス情報を取得
            let response: [PressDevice] = try await supabase
                .from("press_devices")
                .select()
                .eq("device_id", value: deviceId)
                .limit(1)
                .execute()
                .value

            if let device = response.first {
                pressDevice = device

                // 有効性をチェック
                if device.isValid {
                    isPressModeEnabled = true
                    print("✅ プレスモード有効: \(device.organization) - 期限: \(device.expirationDisplayString)")
                } else {
                    isPressModeEnabled = false
                    if !device.isActive {
                        error = "このデバイスのプレスモードは無効化されています。"
                    } else {
                        error = "プレスモードの有効期限が切れています。"
                    }
                    print("❌ プレスモード無効: \(error ?? "")")
                }
            } else {
                // デバイスが登録されていない
                isPressModeEnabled = false
                pressDevice = nil
                print("ℹ️ プレスモード未登録: デバイスID = \(deviceId)")
            }
        } catch {
            self.error = "プレスモード権限の確認に失敗しました: \(error.localizedDescription)"
            isPressModeEnabled = false
            print("❌ エラー: \(error)")
        }

        isLoading = false
    }

    /// プレスモードを手動で無効化
    func disablePressMode() {
        isPressModeEnabled = false
        pressDevice = nil
    }

    /// デバイスIDをクリップボードにコピー（申請用）
    func copyDeviceIdToClipboard() {
        let deviceId = getDeviceId()
        UIPasteboard.general.string = deviceId
        print("📋 デバイスIDをコピー: \(deviceId)")
    }

    /// デバイスIDを取得（表示用）
    func getDeviceIdForDisplay() -> String {
        return getDeviceId()
    }
}
