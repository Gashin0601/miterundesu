//
//  LocalizationManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import Combine

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    @Published var currentLanguage: String = "ja"

    init(language: String = "ja") {
        self.currentLanguage = language
    }

    func updateLanguage(_ language: String) {
        currentLanguage = language
    }

    // ローカライズされたテキストを取得
    func localizedString(_ key: String) -> String {
        switch currentLanguage {
        case "en":
            return englishStrings[key] ?? key
        default:
            return japaneseStrings[key] ?? key
        }
    }

    // 日本語の文字列
    private let japaneseStrings: [String: String] = [
        "app_name": "ミテルンデス",
        "settings": "設定",
        "explanation": "説明を見る",
        "theater_mode": "シアター",
        "close": "閉じる",
        "camera_settings": "カメラ設定",
        "max_zoom": "最大拡大率",
        "language_settings": "言語設定",
        "language": "言語",
        "scrolling_message_settings": "スクロールメッセージ",
        "message_content": "メッセージ内容",
        "app_info": "アプリ情報",
        "version": "バージョン",
        "official_site": "公式サイト",
        "reset_settings": "設定をリセット",
        "zoom_in": "ズームイン",
        "zoom_out": "ズームアウト",
        "zoom_reset": "ズームリセット",
        "capture_disabled": "撮影不可",
        "viewing_disabled": "閲覧不可",
        "remaining_time": "残り時間",
        "latest_image": "最新の撮影画像",
        "screen_recording_warning": "画面録画中は表示できません",
        "no_recording_message": "このアプリでは録画・保存はできません",
        "camera_preparing": "カメラを準備中...",
        "default_scrolling_message": "撮影・録画は行っていません。スマートフォンを拡大鏡として使っています。画像は一時的に保存できますが、10分後には自動的に削除されます。共有やスクリーンショットはできません。",
        "default_scrolling_message_theater": "撮影機能は無効になっています。このアプリは画面の明るさを抑えた状態で、文字や作品を見やすくするためのツールです。画像の保存・録画・共有は一切できません。",
        "normal_mode": "通常モード"
    ]

    // 英語の文字列
    private let englishStrings: [String: String] = [
        "app_name": "Miterundesu",
        "settings": "Settings",
        "explanation": "View Guide",
        "theater_mode": "Theater",
        "close": "Close",
        "camera_settings": "Camera Settings",
        "max_zoom": "Maximum Zoom",
        "language_settings": "Language Settings",
        "language": "Language",
        "scrolling_message_settings": "Scrolling Message",
        "message_content": "Message Content",
        "app_info": "App Information",
        "version": "Version",
        "official_site": "Official Website",
        "reset_settings": "Reset Settings",
        "zoom_in": "Zoom In",
        "zoom_out": "Zoom Out",
        "zoom_reset": "Reset Zoom",
        "capture_disabled": "Capture Disabled",
        "viewing_disabled": "Viewing Disabled",
        "remaining_time": "Time Remaining",
        "latest_image": "Latest Captured Image",
        "screen_recording_warning": "Cannot display during screen recording",
        "no_recording_message": "Recording and saving are not allowed in this app",
        "camera_preparing": "Preparing camera...",
        "default_scrolling_message": "No photos or videos are being taken. This smartphone is being used as a magnifying glass. Images can be temporarily saved but will be automatically deleted after 10 minutes. Sharing and screenshots are not allowed.",
        "default_scrolling_message_theater": "Capture function is disabled. This app is a tool to make text and artwork easier to see with reduced screen brightness. Saving, recording, and sharing images are not allowed.",
        "normal_mode": "Normal Mode"
    ]
}
