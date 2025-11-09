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
                    Section(header: Text("カメラ設定").foregroundColor(.white)) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("最大拡大率")
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
                    Section(header: Text("言語設定").foregroundColor(.white)) {
                        Picker("言語", selection: $settingsManager.language) {
                            ForEach(Language.allCases) { language in
                                Text(language.displayName)
                                    .tag(language.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("アプリの表示言語を選択します。")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 4)
                    }
                    .listRowBackground(Color.white.opacity(0.2))

                    // アプリ情報
                    Section(header: Text("アプリ情報").foregroundColor(.white)) {
                        HStack {
                            Text("バージョン")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .listRowBackground(Color.white.opacity(0.2))

                        Link(destination: URL(string: "https://miterundesu.jp")!) {
                            HStack {
                                Text("公式サイト")
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
                                Text("設定をリセット")
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
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager(), isTheaterMode: false)
}

#Preview("Theater Mode") {
    SettingsView(settingsManager: SettingsManager(), isTheaterMode: true)
}
