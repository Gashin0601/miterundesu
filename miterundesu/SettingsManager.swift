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
    // 設定キー
    private enum Keys {
        static let maxZoomFactor = "maxZoomFactor"
        static let language = "language"
        static let isTheaterMode = "isTheaterMode"
        static let scrollingMessage = "scrollingMessage"
    }

    // 最大拡大率（デフォルト: ×100）
    @Published var maxZoomFactor: Double = 100.0

    // 言語設定（デフォルト: 日本語）
    @Published var language: String = "ja"

    // シアターモード（デフォルト: オフ）
    @Published var isTheaterMode: Bool = false

    // スクロールメッセージ（デフォルト）
    @Published var scrollingMessage: String = "撮影・録画は行っていません。スマートフォンを拡大鏡として使っています。画像は一時的に保存できますが、10分後には自動的に削除されます。共有やスクリーンショットはできません。"

    private var cancellables = Set<AnyCancellable>()

    init() {
        // UserDefaultsから設定を読み込み
        let savedZoom = UserDefaults.standard.double(forKey: Keys.maxZoomFactor)
        if savedZoom > 0 {
            self.maxZoomFactor = savedZoom
        }

        if let savedLanguage = UserDefaults.standard.string(forKey: Keys.language) {
            self.language = savedLanguage
        }

        self.isTheaterMode = UserDefaults.standard.bool(forKey: Keys.isTheaterMode)

        if let savedMessage = UserDefaults.standard.string(forKey: Keys.scrollingMessage), !savedMessage.isEmpty {
            self.scrollingMessage = savedMessage
        }

        // プロパティの変更を監視してUserDefaultsに保存
        $maxZoomFactor
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.maxZoomFactor)
            }
            .store(in: &cancellables)

        $language
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.language)
            }
            .store(in: &cancellables)

        $isTheaterMode
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.isTheaterMode)
            }
            .store(in: &cancellables)

        $scrollingMessage
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: Keys.scrollingMessage)
            }
            .store(in: &cancellables)
    }

    // 設定をデフォルトにリセット
    func resetToDefaults() {
        maxZoomFactor = 100.0
        language = "ja"
        isTheaterMode = false
        scrollingMessage = "撮影・録画は行っていません。スマートフォンを拡大鏡として使っています。画像は一時的に保存できますが、10分後には自動的に削除されます。共有やスクリーンショットはできません。"
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
