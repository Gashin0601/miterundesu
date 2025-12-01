//
//  WhatsNewManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

/// バージョンアップ時の新機能案内を管理するマネージャー
class WhatsNewManager: ObservableObject {
    static let shared = WhatsNewManager()

    private let lastSeenVersionKey = "lastSeenAppVersion"
    private let currentVersion = "1.1.0"

    @Published var shouldShowWhatsNew: Bool = false

    private init() {
        checkForNewVersion()
    }

    /// 新しいバージョンかどうかをチェック
    func checkForNewVersion() {
        let lastSeenVersion = UserDefaults.standard.string(forKey: lastSeenVersionKey)

        // 初回起動の場合（lastSeenVersionがnil）は新機能案内を表示しない
        // 既存ユーザーがアップデートした場合のみ表示
        if let lastVersion = lastSeenVersion {
            // バージョンが異なる場合、かつ1.1.0へのアップデートの場合
            if lastVersion != currentVersion && currentVersion == "1.1.0" {
                shouldShowWhatsNew = true
            }
        } else {
            // 初回起動 - バージョンを保存するだけ
            UserDefaults.standard.set(currentVersion, forKey: lastSeenVersionKey)
        }
    }

    /// 新機能案内を表示済みとしてマーク
    func markWhatsNewAsSeen() {
        UserDefaults.standard.set(currentVersion, forKey: lastSeenVersionKey)
        shouldShowWhatsNew = false
    }
}
