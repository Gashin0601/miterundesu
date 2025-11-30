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
    @Published var showCompletionScreen: Bool = false
    @Published var currentHighlightedIDs: Set<String> = []

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

    /// 機能ハイライト完了後、完了画面を表示
    func completeFeatureHighlights() {
        showFeatureHighlights = false
        showCompletionScreen = true
    }

    /// オンボーディング全体を完了（完了画面の「使い始める」ボタンから）
    func completeOnboarding() {
        showWelcomeScreen = false
        showFeatureHighlights = false
        showCompletionScreen = false
        hasCompletedOnboarding = true
    }

    /// オンボーディングを最初からやり直す（設定画面から呼び出し用）
    func resetOnboarding() {
        hasCompletedOnboarding = false
        showWelcomeScreen = true
    }

    /// チュートリアルを最初から表示（設定画面から呼び出し用）
    /// 必ずウェルカム画面から開始し、「始める」ボタンでハイライトに進む
    func showTutorial() {
        showWelcomeScreen = true
    }
}
