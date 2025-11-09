//
//  SettingsView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                // 最大拡大率設定
                Section(header: Text("カメラ設定")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最大拡大率")
                                .font(.body)
                            Spacer()
                            Text("×\(Int(settingsManager.maxZoomFactor))")
                                .font(.headline)
                                .foregroundColor(.green)
                        }

                        Slider(
                            value: $settingsManager.maxZoomFactor,
                            in: 10...200,
                            step: 10
                        )
                        .tint(.green)

                        HStack {
                            Text("×10")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("×200")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("カメラのズーム機能の最大倍率を設定します。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                // 言語設定
                Section(header: Text("言語設定")) {
                    Picker("言語", selection: $settingsManager.language) {
                        ForEach(Language.allCases) { language in
                            Text(language.displayName)
                                .tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("アプリの表示言語を選択します。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }

                // アプリ情報
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://miterundesu.jp")!) {
                        HStack {
                            Text("公式サイト")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.green)
                        }
                    }
                }

                // リセット
                Section {
                    Button(action: {
                        settingsManager.resetToDefaults()
                    }) {
                        HStack {
                            Spacer()
                            Text("設定をリセット")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
}
