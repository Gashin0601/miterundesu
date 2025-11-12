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
    @State private var showingDeviceIdCopied = false
    @State private var showingPressModeAccess = false
    @State private var showingPressModeInfo = false
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

                            Text("カメラのズーム機能の最大倍率を設定します。")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.2))

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
                    .listRowBackground(Color.white.opacity(0.2))

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
                                        Button("完了") {
                                            isMessageFieldFocused = false
                                        }
                                    }
                                }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.2))

                    // プレスモード設定
                    Section(header: Text(settingsManager.localizationManager.localizedString("press_mode_settings")).foregroundColor(.white)) {
                        VStack(alignment: .leading, spacing: 12) {
                            // プレスモード権限状態
                            if pressModeManager.isPressModeEnabled, let device = pressModeManager.pressDevice {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("プレスモード有効")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }

                                    Text("所属: \(device.organization)")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))

                                    Text("有効期限: \(device.expirationDisplayString)")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))

                                    if device.daysUntilExpiration < 30 {
                                        Text("あと\(device.daysUntilExpiration)日で期限切れです")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .padding(.vertical, 4)
                            } else {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("プレスモード未登録")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 4)
                            }

                            Divider()
                                .background(.white.opacity(0.3))

                            // デバイスID表示とコピー
                            VStack(alignment: .leading, spacing: 8) {
                                Text("デバイスID")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))

                                HStack {
                                    Text(pressModeManager.getDeviceIdForDisplay())
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .truncationMode(.middle)

                                    Spacer()

                                    Button(action: {
                                        pressModeManager.copyDeviceIdToClipboard()
                                        showingDeviceIdCopied = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            showingDeviceIdCopied = false
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: showingDeviceIdCopied ? "checkmark" : "doc.on.doc")
                                            Text(showingDeviceIdCopied ? "コピー済み" : "コピー")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(4)
                                    }
                                }
                            }

                            Text("プレスモードの申請には、このデバイスIDが必要です。")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)

                            Divider()
                                .background(.white.opacity(0.3))

                            // プレスモードトグル（アクセスコード入力必須）
                            Button(action: {
                                if pressModeManager.isPressModeEnabled {
                                    // 権限がある場合：アクセスコード画面を表示
                                    pressModeTargetState = !settingsManager.isPressMode
                                    showingPressModeAccess = true
                                } else {
                                    // 権限がない場合：案内画面を表示
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
                                            .fill(settingsManager.isPressMode ? Color.white : Color.white.opacity(0.3))
                                            .frame(width: 51, height: 31)

                                        Circle()
                                            .fill(settingsManager.isPressMode ? Color("MainGreen") : Color.white)
                                            .frame(width: 27, height: 27)
                                            .offset(x: settingsManager.isPressMode ? 10 : -10)
                                    }
                                }
                            }

                            Text(settingsManager.localizationManager.localizedString("press_mode_description"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.2))

                    // アプリ情報
                    Section(header: Text(settingsManager.localizationManager.localizedString("app_info")).foregroundColor(.white)) {
                        HStack {
                            Text(settingsManager.localizationManager.localizedString("version"))
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .listRowBackground(Color.white.opacity(0.2))

                        Link(destination: URL(string: "https://miterundesu.jp")!) {
                            HStack {
                                Text(settingsManager.localizationManager.localizedString("official_site"))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.white)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.2))
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
                        .listRowBackground(Color.white.opacity(0.2))
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
                isPressMode: $settingsManager.isPressMode,
                targetState: pressModeTargetState
            )
        }
        .sheet(isPresented: $showingPressModeInfo) {
            PressModeInfoView()
                .environmentObject(pressModeManager)
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
