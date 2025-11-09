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
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
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
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager(), isTheaterMode: false)
}

#Preview("Theater Mode") {
    SettingsView(settingsManager: SettingsManager(), isTheaterMode: true)
}
