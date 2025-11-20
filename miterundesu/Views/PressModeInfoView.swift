//
//  PressModeInfoView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

/// プレスモード未登録時の案内画面
struct PressModeInfoView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pressModeManager: PressModeManager
    @ObservedObject var settingsManager: SettingsManager
    @State private var showingDeviceIdCopied = false

    private let contactEmail = "press@miterundesu.jp"

    var body: some View {
        NavigationView {
            ZStack {
                Color("MainGreen")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 20)

                        // アイコン
                        Image(systemName: "newspaper.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)

                        // タイトル
                        Text(settingsManager.localizationManager.localizedString("press_mode_about"))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        // 説明セクション
                        VStack(spacing: 24) {
                            // プレスモードとは
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.white)
                                    Text(settingsManager.localizationManager.localizedString("press_mode_what_is"))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                Text(settingsManager.localizationManager.localizedString("press_mode_what_is_desc"))
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)

                            // 対象者
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "person.badge.shield.checkmark.fill")
                                        .foregroundColor(.white)
                                    Text(settingsManager.localizationManager.localizedString("press_mode_target_users"))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(settingsManager.localizationManager.localizedString("press_mode_target_newspapers"))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(settingsManager.localizationManager.localizedString("press_mode_target_tv"))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(settingsManager.localizationManager.localizedString("press_mode_target_magazines"))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(settingsManager.localizationManager.localizedString("press_mode_target_other"))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                .font(.body)
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)

                            // 申請方法
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "envelope.badge.fill")
                                        .foregroundColor(.white)
                                    Text(settingsManager.localizationManager.localizedString("press_mode_application"))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                Text(settingsManager.localizationManager.localizedString("press_mode_application_desc"))
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)

                                // デバイスID表示
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(settingsManager.localizationManager.localizedString("press_mode_your_device_id"))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))

                                    HStack {
                                        Text(pressModeManager.getDeviceIdForDisplay())
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.8)

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
                                                Text(settingsManager.localizationManager.localizedString(showingDeviceIdCopied ? "press_mode_copied" : "press_mode_copy"))
                                            }
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.3))
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)

                        // 詳細と申請フォームへのリンク
                        VStack(spacing: 16) {
                            Text(settingsManager.localizationManager.localizedString("press_mode_application"))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            Link(destination: URL(string: "https://miterundesu.jp/press")!) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.up.forward.square.fill")
                                        .font(.title3)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(settingsManager.localizationManager.localizedString("press_mode_application_form"))
                                            .font(.headline)
                                        Text("miterundesu.jp/press")
                                            .font(.caption)
                                    }
                                }
                                .foregroundColor(Color("MainGreen"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .accessibilityLabel(settingsManager.localizationManager.localizedString("press_mode_application_form") + ": miterundesu.jp/press")
                            .accessibilityHint("リンクを開く")
                            .padding(.horizontal, 24)
                        }

                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("閉じる")
                }
            }
            .toolbarBackground(Color("MainGreen"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    PressModeInfoView(settingsManager: SettingsManager())
        .environmentObject(PressModeManager.shared)
}
