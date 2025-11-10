//
//  SettingsManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import Combine

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    @Published var localizationManager = LocalizationManager()
    // 設定キー
    private enum Keys {
        static let maxZoomFactor = "maxZoomFactor"
        static let language = "language"
        static let isTheaterMode = "isTheaterMode"
        static let scrollingMessageNormal = "scrollingMessageNormal"
        static let scrollingMessageTheater = "scrollingMessageTheater"
        static let isPressMode = "isPressMode"
    }

    // 最大拡大率（デフォルト: ×100）
    @Published var maxZoomFactor: Double = 100.0

    // 言語設定（デフォルト: 日本語）
    @Published var language: String = "ja"

    // シアターモード（デフォルト: オフ）
    @Published var isTheaterMode: Bool = false

    // プレスモード（報道・開発用、デフォルト: オフ）
    @Published var isPressMode: Bool = false

    // スクロールメッセージ - 通常モード用
    @Published var scrollingMessageNormal: String = ""

    // スクロールメッセージ - シアターモード用
    @Published var scrollingMessageTheater: String = ""

    // 現在のモードに応じたスクロールメッセージを返す
    var scrollingMessage: String {
        isTheaterMode ? scrollingMessageTheater : scrollingMessageNormal
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        // UserDefaultsから設定を読み込み
        let savedZoom = UserDefaults.standard.double(forKey: Keys.maxZoomFactor)
        if savedZoom > 0 {
            self.maxZoomFactor = savedZoom
        }

        if let savedLanguage = UserDefaults.standard.string(forKey: Keys.language) {
            self.language = savedLanguage
        } else {
            self.language = "ja"
        }

        // LocalizationManagerを言語で初期化
        self.localizationManager = LocalizationManager(language: self.language)

        self.isTheaterMode = UserDefaults.standard.bool(forKey: Keys.isTheaterMode)

        self.isPressMode = UserDefaults.standard.bool(forKey: Keys.isPressMode)

        // 通常モード用メッセージの読み込み
        if let savedMessageNormal = UserDefaults.standard.string(forKey: Keys.scrollingMessageNormal), !savedMessageNormal.isEmpty {
            self.scrollingMessageNormal = savedMessageNormal
        } else {
            // デフォルトメッセージ（日本語固定）
            self.scrollingMessageNormal = "撮影・録画は行っていません。スマートフォンを拡大鏡として使っています。画像は一時的に保存できますが、10分後には自動的に削除されます。共有やスクリーンショットはできません。"
        }

        // シアターモード用メッセージの読み込み
        if let savedMessageTheater = UserDefaults.standard.string(forKey: Keys.scrollingMessageTheater), !savedMessageTheater.isEmpty {
            self.scrollingMessageTheater = savedMessageTheater
        } else {
            // デフォルトメッセージ（日本語固定）
            self.scrollingMessageTheater = "撮影・録画は行っていません。スマートフォンを拡大鏡として使用しています。スクリーンショットや画面収録を含め、一切の保存ができないカメラアプリですので、ご安心ください。"
        }

        // プロパティの変更を監視してUserDefaultsに保存
        $maxZoomFactor
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.maxZoomFactor)
            }
            .store(in: &cancellables)

        $language
            .sink { [weak self] newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.language)
                // LocalizationManagerを更新
                self?.localizationManager.updateLanguage(newValue)
            }
            .store(in: &cancellables)

        $isTheaterMode
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.isTheaterMode)
            }
            .store(in: &cancellables)

        $isPressMode
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.isPressMode)
            }
            .store(in: &cancellables)

        $scrollingMessageNormal
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.scrollingMessageNormal)
            }
            .store(in: &cancellables)

        $scrollingMessageTheater
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.scrollingMessageTheater)
            }
            .store(in: &cancellables)
    }

    // 設定をデフォルトにリセット
    func resetToDefaults() {
        maxZoomFactor = 100.0
        language = "ja"
        isTheaterMode = false
        isPressMode = false
        scrollingMessageNormal = "撮影・録画は行っていません。スマートフォンを拡大鏡として使っています。画像は一時的に保存できますが、10分後には自動的に削除されます。共有やスクリーンショットはできません。"
        scrollingMessageTheater = "撮影・録画は行っていません。スマートフォンを拡大鏡として使用しています。スクリーンショットや画面収録を含め、一切の保存ができないカメラアプリですので、ご安心ください。"
    }
}

// MARK: - Language
enum Language: String, CaseIterable, Identifiable {
    case japanese = "ja"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .japanese:
            return "日本語"
        case .english:
            return "English"
        }
    }
}
