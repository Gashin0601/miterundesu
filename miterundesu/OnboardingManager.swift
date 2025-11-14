//
//  OnboardingManager.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import Combine

// MARK: - Onboarding Manager
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    @Published var showWelcomeScreen: Bool = false
    @Published var showFeatureHighlights: Bool = false

    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    /// アプリ起動時に呼び出して、オンボーディングを表示するかチェック
    func checkOnboardingStatus() {
        if !hasCompletedOnboarding {
            showWelcomeScreen = true
        }
    }

    /// ウェルカム画面完了後、機能ハイライトを表示
    func completeWelcomeScreen() {
        showWelcomeScreen = false
        showFeatureHighlights = true
    }

    /// オンボーディング全体を完了
    func completeOnboarding() {
        showFeatureHighlights = false
        hasCompletedOnboarding = true
    }

    /// オンボーディングを最初からやり直す（設定画面から呼び出し用）
    func resetOnboarding() {
        hasCompletedOnboarding = false
        showWelcomeScreen = true
    }

    /// 機能ハイライトのみを再表示（設定画面から呼び出し用）
    func showTutorial() {
        showFeatureHighlights = true
    }
}
