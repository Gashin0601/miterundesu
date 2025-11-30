//
//  SettingsView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    let isTheaterMode: Bool
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @FocusState private var isMessageFieldFocused: Bool
    @EnvironmentObject var pressModeManager: PressModeManager
    @ObservedObject private var onboardingManager = OnboardingManager.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var showingPressModeLogin = false
    @State private var showingPressModeInfo = false
    @State private var showingPressModeStatus = false
    @State private var pressModeTargetState = false
    @State private var showingLogoutConfirmation = false
    @State private var showingResetConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                (isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"))
                    .ignoresSafeArea()

                Form {
                    // 最大拡大率設定
                    Section(header: Text(settingsManager.localizationManager.localizedString("camera_settings")).foregroundColor(.white)) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(settingsManager.localizationManager.localizedString("max_zoom"))
                                    .font(.body)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("×\(Int(settingsManager.maxZoomFactor))")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }

                            Slider(
                                value: $settingsManager.maxZoomFactor,
                                in: 10...200,
                                step: 10
                            )
                            .tint(.white)

                            HStack {
                                Text("×10")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("×200")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Text(settingsManager.localizationManager.localizedString("camera_zoom_description"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        isTheaterMode
                            ? Color(red: 0.95, green: 0.6, blue: 0.3, opacity: 0.35)
                            : Color(red: 0.2, green: 0.6, blue: 0.4, opacity: 0.35)
                    )

                    // 言語設定
                    Section(header: Text(settingsManager.localizationManager.localizedString("language_settings")).foregroundColor(.white)) {
                        Picker(settingsManager.localizationManager.localizedString("language"), selection: $settingsManager.language) {
                            ForEach(Language.allCases) { language in
                                Text(language.displayName)
                                    .tag(language.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(
                        isTheaterMode
                            ? Color(red: 0.95, green: 0.6, blue: 0.3, opacity: 0.35)
                            : Color(red: 0.2, green: 0.6, blue: 0.4, opacity: 0.35)
                    )

                    // スクロールメッセージ設定
                    Section(header: Text(settingsManager.localizationManager.localizedString("scrolling_message_settings")).foregroundColor(.white)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(settingsManager.localizationManager.localizedString("message_content"))
                                    .font(.body)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(settingsManager.isTheaterMode ? settingsManager.localizationManager.localizedString("theater_mode") : settingsManager.localizationManager.localizedString("normal_mode"))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }

                            TextEditor(text: settingsManager.isTheaterMode ? $settingsManager.scrollingMessageTheater : $settingsManager.scrollingMessageNormal)
                                .frame(minHeight: 100, maxHeight: 200)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .focused($isMessageFieldFocused)
                                .onChange(of: settingsManager.isTheaterMode ? settingsManager.scrollingMessageTheater : settingsManager.scrollingMessageNormal) { oldValue, newValue in
                                    // 改行文字を即座に削除（入力・ペースト両方に対応）
                                    let cleaned = newValue.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
                                    if settingsManager.isTheaterMode {
                                        if cleaned != newValue {
                                            settingsManager.scrollingMessageTheater = cleaned
                                        }
                                    } else {
                                        if cleaned != newValue {
                                            settingsManager.scrollingMessageNormal = cleaned
                                        }
                                    }
                                }
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button(settingsManager.localizationManager.localizedString("done")) {
                                            isMessageFieldFocused = false
                                        }
                                    }
                                }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        isTheaterMode
                            ? Color(red: 0.95, green: 0.6, blue: 0.3, opacity: 0.35)
                            : Color(red: 0.2, green: 0.6, blue: 0.4, opacity: 0.35)
                    )

                    // プレスモード設定
                    Section(header: Text(settingsManager.localizationManager.localizedString("press_mode_settings")).foregroundColor(.white)) {
                        VStack(alignment: .leading, spacing: 12) {
                            // プレスモード権限状態
                            if let account = pressModeManager.pressAccount {
                                VStack(alignment: .leading, spacing: 8) {
                                    // 状態アイコンとタイトル
                                    HStack {
                                        statusIcon(for: account.status)
                                        statusText(for: account.status)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .accessibilityElement(children: .combine)

                                    // 組織名を表示
                                    Text("\(account.organizationName)")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))

                                    // ユーザーIDを表示
                                    Text("User ID: \(account.userId)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))

                                    // 有効期間内の場合は期限を表示
                                    if account.status == .active {
                                        Text("\(settingsManager.localizationManager.localizedString("expiration_date")): \(account.expirationDisplayString)")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))

                                        if account.daysUntilExpiration < 30 {
                                            Text(settingsManager.localizationManager.localizedString("press_mode_status_expires_soon").replacingOccurrences(of: "{days}", with: "\(account.daysUntilExpiration)"))
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                        }
                                    } else {
                                        // 期限切れ・無効化の場合は期限を表示
                                        Text("\(settingsManager.localizationManager.localizedString("expiration_date")): \(account.expirationDisplayString)")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }

                                    // ログアウトボタン
                                    Button(action: {
                                        showingLogoutConfirmation = true
                                    }) {
                                        HStack {
                                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                            Text(settingsManager.localizationManager.localizedString("press_logout"))
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.red.opacity(networkMonitor.isConnected ? 0.3 : 0.15))
                                        .cornerRadius(8)
                                    }
                                    .disabled(!networkMonitor.isConnected)
                                    .opacity(networkMonitor.isConnected ? 1.0 : 0.5)
                                    .accessibilityHint(!networkMonitor.isConnected ? settingsManager.localizationManager.localizedString("offline_indicator") : "")
                                }
                                .padding(.vertical, 4)
                            } else {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.white.opacity(0.7))
                                            .accessibilityHidden(true)
                                        Text(settingsManager.localizationManager.localizedString("press_not_logged_in"))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .accessibilityElement(children: .combine)

                                    // ウェブサイト案内
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(settingsManager.localizationManager.localizedString("press_apply_description"))
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                            .fixedSize(horizontal: false, vertical: true)

                                        Button(action: {
                                            if let url = URL(string: "https://miterundesu.jp/press") {
                                                openURL(url)
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "globe")
                                                    .font(.caption)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(settingsManager.localizationManager.localizedString("press_apply_button"))
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                    Text("miterundesu.jp/press")
                                                        .font(.caption)
                                                }
                                                Spacer()
                                                Image(systemName: "arrow.up.forward")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }

                            Divider()
                                .background(.white.opacity(0.3))

                            // プレスモードトグル
                            Button(action: {
                                if let account = pressModeManager.pressAccount {
                                    // ログイン済みの場合
                                    switch account.status {
                                    case .active:
                                        // 有効期間内
                                        if settingsManager.isPressMode {
                                            // オフにする場合：直接オフ
                                            settingsManager.isPressMode = false
                                        } else {
                                            // オンにする場合：直接オン
                                            settingsManager.isPressMode = true
                                        }
                                    case .expired, .deactivated:
                                        // 期限切れ・無効化：状態画面を表示
                                        showingPressModeStatus = true
                                    }
                                } else {
                                    // 未ログイン：ログイン画面を表示
                                    showingPressModeLogin = true
                                }
                            }) {
                                HStack {
                                    Text(settingsManager.localizationManager.localizedString("press_mode"))
                                        .font(.body)
                                        .foregroundColor(.white)

                                    Spacer()

                                    // トグル風の表示
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(settingsManager.isPressMode
                                                ? Color.red.opacity(0.6)
                                                : Color.white.opacity(0.3))
                                            .frame(width: 51, height: 31)

                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 27, height: 27)
                                            .offset(x: settingsManager.isPressMode ? 10 : -10)
                                    }
                                    .accessibilityHidden(true)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(!networkMonitor.isConnected)
                            .accessibilityLabel(settingsManager.isPressMode ? settingsManager.localizationManager.localizedString("press_mode_turn_off") : settingsManager.localizationManager.localizedString("press_mode_turn_on"))
                            .accessibilityValue(settingsManager.isPressMode ? settingsManager.localizationManager.localizedString("on") : settingsManager.localizationManager.localizedString("off"))
                            .accessibilityHint(!networkMonitor.isConnected ? settingsManager.localizationManager.localizedString("offline_indicator") : "")
                            .opacity(networkMonitor.isConnected ? 1.0 : 0.5)

                            Text(settingsManager.localizationManager.localizedString("press_mode_description"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)

                            // オフライン時の警告表示
                            if !networkMonitor.isConnected {
                                HStack(spacing: 6) {
                                    Image(systemName: "wifi.slash")
                                        .font(.caption)
                                        .accessibilityHidden(true)
                                    Text(settingsManager.localizationManager.localizedString("offline_indicator"))
                                        .font(.caption)
                                }
                                .foregroundColor(isTheaterMode ? .red : .orange)
                                .padding(.top, 4)
                                .accessibilityElement(children: .combine)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        isTheaterMode
                            ? Color(red: 0.95, green: 0.6, blue: 0.3, opacity: 0.35)
                            : Color(red: 0.2, green: 0.6, blue: 0.4, opacity: 0.35)
                    )

                    // アプリ情報
                    Section(header: Text(settingsManager.localizationManager.localizedString("app_info")).foregroundColor(.white)) {
                        HStack {
                            Text(settingsManager.localizationManager.localizedString("version"))
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.1")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(settingsManager.localizationManager.localizedString("version_info")) 1.0.1")
                        .listRowBackground(
                        isTheaterMode
                            ? Color(red: 0.95, green: 0.6, blue: 0.3, opacity: 0.35)
                            : Color(red: 0.2, green: 0.6, blue: 0.4, opacity: 0.35)
                    )

                        Link(destination: URL(string: "https://miterundesu.jp")!) {
                            HStack {
                                Text(settingsManager.localizationManager.localizedString("official_site"))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.white)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel(settingsManager.localizationManager.localizedString("official_site"))
                        .accessibilityHint(settingsManager.localizationManager.localizedString("open_link"))
                        .listRowBackground(
                        isTheaterMode
                            ? Color(red: 0.95, green: 0.6, blue: 0.3, opacity: 0.35)
                            : Color(red: 0.2, green: 0.6, blue: 0.4, opacity: 0.35)
                    )

                        Button(action: {
                            // 設定画面を閉じてからチュートリアルを表示
                            dismiss()
                            // 少し遅延させてから表示（dismissのアニメーション完了後）
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onboardingManager.showTutorial()
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(settingsManager.localizationManager.localizedString("show_tutorial"))
                                        .foregroundColor(isTheaterMode ? .white.opacity(0.5) : .white)
                                    Spacer()
                                    Image(systemName: "questionmark.circle")
                                        .foregroundColor(isTheaterMode ? .white.opacity(0.5) : .white)
                                        .accessibilityHidden(true)
                                }
                                // シアターモード時の説明
                                if isTheaterMode {
                                    Text(settingsManager.localizationManager.localizedString("tutorial_unavailable_theater"))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .disabled(isTheaterMode)
                        .accessibilityLabel(settingsManager.localizationManager.localizedString("show_tutorial"))
                        .accessibilityHint(isTheaterMode ? settingsManager.localizationManager.localizedString("tutorial_unavailable_theater") : "")
                        .listRowBackground(
                            isTheaterMode
                                ? Color(red: 0.95, green: 0.6, blue: 0.3, opacity: 0.35)
                                : Color(red: 0.2, green: 0.6, blue: 0.4, opacity: 0.35)
                        )

                        Link(destination: URL(string: "https://miterundesu.jp/privacy")!) {
                            HStack {
                                Text(settingsManager.localizationManager.localizedString("privacy_policy"))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.white)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel(settingsManager.localizationManager.localizedString("privacy_policy"))
                        .accessibilityHint(settingsManager.localizationManager.localizedString("open_link"))
                        .listRowBackground(
                        isTheaterMode
                            ? Color(red: 0.95, green: 0.6, blue: 0.3, opacity: 0.35)
                            : Color(red: 0.2, green: 0.6, blue: 0.4, opacity: 0.35)
                    )

                        Link(destination: URL(string: "https://miterundesu.jp/terms")!) {
                            HStack {
                                Text(settingsManager.localizationManager.localizedString("terms_of_service"))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.white)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel(settingsManager.localizationManager.localizedString("terms_of_service"))
                        .accessibilityHint(settingsManager.localizationManager.localizedString("open_link"))
                        .listRowBackground(
                        isTheaterMode
                            ? Color(red: 0.95, green: 0.6, blue: 0.3, opacity: 0.35)
                            : Color(red: 0.2, green: 0.6, blue: 0.4, opacity: 0.35)
                    )
                    }

                    // リセット
                    Section {
                        Button(action: {
                            showingResetConfirmation = true
                        }) {
                            HStack {
                                Spacer()
                                Text(settingsManager.localizationManager.localizedString("reset_settings"))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .listRowBackground(
                        isTheaterMode
                            ? Color(red: 0.95, green: 0.6, blue: 0.3, opacity: 0.35)
                            : Color(red: 0.2, green: 0.6, blue: 0.4, opacity: 0.35)
                    )
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .listStyle(.plain)
            }
            .navigationTitle(settingsManager.localizationManager.localizedString("settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    TheaterModeToggle(
                        isTheaterMode: $settingsManager.isTheaterMode,
                        onToggle: {},
                        settingsManager: settingsManager
                    )
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: UIScreen.main.bounds.width * 0.07))
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingPressModeLogin) {
            PressModeLoginView()
                .environmentObject(pressModeManager)
        }
        .sheet(isPresented: $showingPressModeInfo) {
            PressModeInfoView(settingsManager: settingsManager)
                .environmentObject(pressModeManager)
        }
        .sheet(isPresented: $showingPressModeStatus) {
            if let account = pressModeManager.pressAccount {
                PressModeAccountStatusView(settingsManager: settingsManager, account: account)
            }
        }
        .onChange(of: pressModeManager.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                // ログイン成功時に自動的にプレスモードをオンにする
                if pressModeManager.pressAccount?.isValid == true {
                    settingsManager.isPressMode = true
                }
            } else {
                // ログアウト時は必ずプレスモードをオフにする
                settingsManager.isPressMode = false
            }
        }
        .alert(settingsManager.localizationManager.localizedString("logout_confirm_title"), isPresented: $showingLogoutConfirmation) {
            Button(settingsManager.localizationManager.localizedString("cancel"), role: .cancel) { }
            Button(settingsManager.localizationManager.localizedString("press_logout"), role: .destructive) {
                pressModeManager.logout()
                settingsManager.isPressMode = false
            }
        } message: {
            Text(settingsManager.localizationManager.localizedString("logout_confirm_message"))
        }
        .alert(settingsManager.localizationManager.localizedString("reset_confirm_title"), isPresented: $showingResetConfirmation) {
            Button(settingsManager.localizationManager.localizedString("cancel"), role: .cancel) { }
            Button(settingsManager.localizationManager.localizedString("reset_confirm_button"), role: .destructive) {
                settingsManager.resetToDefaults()
            }
        } message: {
            Text(settingsManager.localizationManager.localizedString("reset_confirm_message"))
        }
    }

    // MARK: - Helper Functions

    private func statusIcon(for status: PressAccountStatus) -> some View {
        Group {
            switch status {
            case .active:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .expired:
                Image(systemName: "clock.badge.xmark")
                    .foregroundColor(.orange)
            case .deactivated:
                Image(systemName: "xmark.shield")
                    .foregroundColor(.red)
            }
        }
    }

    private func statusText(for status: PressAccountStatus) -> Text {
        switch status {
        case .active:
            return Text(settingsManager.localizationManager.localizedString("press_mode_status_active"))
        case .expired:
            return Text(settingsManager.localizationManager.localizedString("press_mode_status_expired"))
        case .deactivated:
            return Text(settingsManager.localizationManager.localizedString("press_mode_status_deactivated"))
        }
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager(), isTheaterMode: false)
        .environmentObject(PressModeManager.shared)
}

#Preview("Theater Mode") {
    SettingsView(settingsManager: SettingsManager(), isTheaterMode: true)
        .environmentObject(PressModeManager.shared)
}
