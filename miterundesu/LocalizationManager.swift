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
        // アプリ名は常に日本語表示（外国から来た日本人対象のため）
        if key == "app_name" {
            return "ミテルンデス"
        }

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
        "default_scrolling_message_theater": "撮影・録画は行っていません。スマートフォンを拡大鏡として使用しています。スクリーンショットや画面収録を含め、一切の保存ができないカメラアプリですので、ご安心ください。",
        "normal_mode": "通常モード",
        "press_mode_settings": "プレスモード",
        "press_mode": "プレスモードを有効化",
        "press_mode_description": "報道・開発用モード。有効にすると、スクリーンショットや画面録画が可能になります。取材やアプリ開発時にのみ使用してください。",
        "welcome_title": "ようこそ",
        "welcome_message": "ミテルンデスは、撮影ではなく「見る」ためのアプリです",
        "feature_magnify": "拡大鏡として使う",
        "feature_magnify_desc": "スマートフォンのカメラを使って、見えにくいものを拡大して確認できます",
        "feature_privacy": "プライバシー重視",
        "feature_privacy_desc": "撮影した画像は10分後に自動削除。スクリーンショットも無効化されています",
        "feature_theater": "シアターモード",
        "feature_theater_desc": "映画館や美術館など、静かな場所でも安心して使えるモードです",
        "get_started": "始める",
        "skip": "スキップ",
        "tutorial": "チュートリアル",
        "show_tutorial": "チュートリアルを見る",
        "tutorial_zoom_title": "ズーム操作",
        "tutorial_zoom_desc": "これらのボタンを押して拡大縮小や一気に1倍にできます。iPhone１６シリーズ以降をご利用の場合は右側のカメラコントロールをスクロールしても拡大縮小できます",
        "tutorial_capture_title": "撮影機能",
        "tutorial_capture_desc": "一時的に画像を撮影できます。拡大するのが目的なので10分後に自動的に削除されます",
        "tutorial_theater_title": "シアターモード",
        "tutorial_theater_desc": "映画館や美術館ではシアターモードをご利用ください。こちらから切り替えることができます。この時は画像の撮影は一切できなくなります",
        "tutorial_message_title": "メッセージ機能",
        "tutorial_message_desc": "注意されないよう常にメッセージが流れ、注意を受けたときは説明ボタンから詳細な説明を見てもらうことができます",
        "tutorial_settings_title": "設定",
        "tutorial_settings_desc": "こちらからスクロールメッセージや最大の拡大倍率などを変更できます",
        "tutorial_back": "戻る",
        "tutorial_next": "次へ",
        "tutorial_complete": "完了",
        "tutorial_completion_title": "お疲れ様でした！",
        "tutorial_completion_message": "ミテルンデスの使い方を学びました。\n早速使ってみましょう！",
        "start_using": "使い始める",
        "privacy_policy": "プライバシーポリシー",
        "terms_of_service": "利用規約"
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
        "default_scrolling_message_theater": "No photos or videos are being taken. This smartphone is being used as a magnifying glass. This camera app does not allow any saving, including screenshots and screen recording, so you can rest assured.",
        "normal_mode": "Normal Mode",
        "press_mode_settings": "Press Mode",
        "press_mode": "Enable Press Mode",
        "press_mode_description": "Mode for press and development. When enabled, screenshots and screen recording are allowed. Use only for press coverage or app development.",
        "welcome_title": "Welcome",
        "welcome_message": "Miterundesu is for viewing, not recording",
        "feature_magnify": "Use as Magnifier",
        "feature_magnify_desc": "Use your smartphone camera to magnify and view things that are hard to see",
        "feature_privacy": "Privacy Focused",
        "feature_privacy_desc": "Images are automatically deleted after 10 minutes. Screenshots are disabled",
        "feature_theater": "Theater Mode",
        "feature_theater_desc": "A mode designed for quiet places like movie theaters and museums",
        "get_started": "Get Started",
        "skip": "Skip",
        "tutorial": "Tutorial",
        "show_tutorial": "Show Tutorial",
        "tutorial_zoom_title": "Zoom Controls",
        "tutorial_zoom_desc": "Press these buttons to zoom in/out or return to 1x. If using iPhone 16 series or later, you can also scroll the camera control on the right side to zoom",
        "tutorial_capture_title": "Capture Feature",
        "tutorial_capture_desc": "You can temporarily capture images. They are automatically deleted after 10 minutes as this app is for viewing, not recording",
        "tutorial_theater_title": "Theater Mode",
        "tutorial_theater_desc": "Please use Theater Mode in movie theaters and museums. You can switch from here. When enabled, image capture is completely disabled",
        "tutorial_message_title": "Message Feature",
        "tutorial_message_desc": "A message is constantly displayed to avoid being warned. When questioned, you can show detailed explanations from the explanation button",
        "tutorial_settings_title": "Settings",
        "tutorial_settings_desc": "You can change the scrolling message, maximum zoom level, and more from here",
        "tutorial_back": "Back",
        "tutorial_next": "Next",
        "tutorial_complete": "Complete",
        "tutorial_completion_title": "Well Done!",
        "tutorial_completion_message": "You've learned how to use Miterundesu.\nLet's start using it!",
        "start_using": "Start Using",
        "privacy_policy": "Privacy Policy",
        "terms_of_service": "Terms of Service"
    ]
}
