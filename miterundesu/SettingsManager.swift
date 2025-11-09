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
    }

    // 最大拡大率（デフォルト: ×100）
    @Published var maxZoomFactor: Double = 100.0

    // 言語設定（デフォルト: 日本語）
    @Published var language: String = "ja"

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
    }

    // 設定をデフォルトにリセット
    func resetToDefaults() {
        maxZoomFactor = 100.0
        language = "ja"
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
