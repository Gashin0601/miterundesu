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
    @FocusState private var isMessageFieldFocused: Bool
    @EnvironmentObject var pressModeManager: PressModeManager
    @ObservedObject private var onboardingManager = OnboardingManager.shared
    @State private var showingPressModeAccess = false
    @State private var showingPressModeInfo = false
    @State private var showingPressModeStatus = false
    @State private var pressModeTargetState = false

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
                                .frame(minHeight: 60, maxHeight: 120)
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
                            if let device = pressModeManager.pressDevice {
                                VStack(alignment: .leading, spacing: 8) {
                                    // 状態アイコンとタイトル
                                    HStack {
                                        statusIcon(for: device.status)
                                        statusText(for: device.status)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .accessibilityElement(children: .combine)

                                    // 有効期間内の場合は期限を表示
                                    if device.status == .active {
                                        Text("\(settingsManager.localizationManager.localizedString("expiration_date")): \(device.expirationDisplayString)")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))

                                        if device.daysUntilExpiration < 30 {
                                            Text(settingsManager.localizationManager.localizedString("press_mode_status_expires_soon").replacingOccurrences(of: "{days}", with: "\(device.daysUntilExpiration)"))
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                        }
                                    } else {
                                        // 期限切れ、未開始、無効化の場合は期間を表示
                                        Text("\(settingsManager.localizationManager.localizedString("usage_period")): \(device.periodDisplayString)")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                .padding(.vertical, 4)
                            } else {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.white.opacity(0.7))
                                        .accessibilityHidden(true)
                                    Text(settingsManager.localizationManager.localizedString("press_mode_status_not_registered"))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .accessibilityElement(children: .combine)
                                .padding(.vertical, 4)
                            }

                            Divider()
                                .background(.white.opacity(0.3))

                            // プレスモードトグル
                            Button(action: {
                                if let device = pressModeManager.pressDevice {
                                    // デバイスが登録されている場合
                                    switch device.status {
                                    case .active:
                                        // 有効期間内
                                        if settingsManager.isPressMode {
                                            // オフにする場合：認証不要で直接オフ
                                            settingsManager.isPressMode = false
                                        } else {
                                            // オンにする場合：認証チェック
                                            if pressModeManager.isAuthenticated() {
                                                // 認証済み：直接オン
                                                settingsManager.isPressMode = true
                                            } else {
                                                // 未認証：アクセスコード画面を表示
                                                pressModeTargetState = true
                                                showingPressModeAccess = true
                                            }
                                        }
                                    case .expired, .notStarted, .deactivated:
                                        // 期限切れ、未開始、無効化：状態画面を表示
                                        showingPressModeStatus = true
                                    }
                                } else {
                                    // デバイスが未登録：案内画面を表示
                                    showingPressModeInfo = true
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
                                            .fill(settingsManager.isPressMode ? Color("MainGreen") : Color.white.opacity(0.3))
                                            .frame(width: 51, height: 31)

                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 27, height: 27)
                                            .offset(x: settingsManager.isPressMode ? 10 : -10)
                                    }
                                    .accessibilityHidden(true)
                                }
                            }
                            .accessibilityLabel(settingsManager.isPressMode ? settingsManager.localizationManager.localizedString("press_mode_turn_off") : settingsManager.localizationManager.localizedString("press_mode_turn_on"))
                            .accessibilityValue(settingsManager.isPressMode ? settingsManager.localizationManager.localizedString("on") : settingsManager.localizationManager.localizedString("off"))

                            Text(settingsManager.localizationManager.localizedString("press_mode_description"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
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
                            Text("1.0.0")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(settingsManager.localizationManager.localizedString("version_info")) 1.0.0")
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
                            HStack {
                                Text(settingsManager.localizationManager.localizedString("show_tutorial"))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.white)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel(settingsManager.localizationManager.localizedString("show_tutorial"))
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
                            settingsManager.resetToDefaults()
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
        .sheet(isPresented: $showingPressModeAccess) {
            PressModeAccessView(
                settingsManager: settingsManager,
                isPressMode: $settingsManager.isPressMode,
                targetState: pressModeTargetState
            )
            .environmentObject(pressModeManager)
        }
        .sheet(isPresented: $showingPressModeInfo) {
            PressModeInfoView(settingsManager: settingsManager)
                .environmentObject(pressModeManager)
        }
        .sheet(isPresented: $showingPressModeStatus) {
            if let device = pressModeManager.pressDevice {
                PressModeStatusView(settingsManager: settingsManager, device: device)
            }
        }
    }

    // MARK: - Helper Functions

    private func statusIcon(for status: PressDeviceStatus) -> some View {
        Group {
            switch status {
            case .active:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .expired:
                Image(systemName: "clock.badge.xmark")
                    .foregroundColor(.orange)
            case .notStarted:
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(.yellow)
            case .deactivated:
                Image(systemName: "xmark.shield")
                    .foregroundColor(.red)
            }
        }
    }

    private func statusText(for status: PressDeviceStatus) -> Text {
        switch status {
        case .active:
            return Text(settingsManager.localizationManager.localizedString("press_mode_status_active"))
        case .expired:
            return Text(settingsManager.localizationManager.localizedString("press_mode_status_expired"))
        case .notStarted:
            return Text(settingsManager.localizationManager.localizedString("press_mode_not_started"))
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
