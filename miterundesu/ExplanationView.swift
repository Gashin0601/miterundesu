//
//  ExplanationView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

struct ExplanationView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // 背景色
            (settingsManager.isTheaterMode ? Color("TheaterOrange") : Color("MainGreen"))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 上部固定ヘッダー
                ZStack {
                    // 中央：ロゴ（完全に中央配置）
                    Text(settingsManager.localizationManager.localizedString("app_name"))
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.white)

                    // 左右のボタンを絶対配置
                    HStack {
                        // 左：シアターモードトグル
                        TheaterModeToggle(
                            isTheaterMode: $settingsManager.isTheaterMode,
                            onToggle: {},
                            settingsManager: settingsManager
                        )
                        .padding(.leading, 20)

                        Spacer()

                        // 右：閉じるボタン
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 20)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // スペーサー（ヘッダー分）
                    Spacer()
                        .frame(height: 8)

                    // タイトル
                    Text("撮影しているわけではなく、\n拡大して見ているんです。")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 24)

                    // 本文
                    Text(bodyText)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(8)
                        .padding(.horizontal, 24)

                    // イラストセクション
                    if settingsManager.isTheaterMode {
                        TheaterModeIllustrations()
                    } else {
                        NormalModeIllustrations()
                    }

                    Spacer(minLength: 40)

                    // フッターセクション
                    VStack(spacing: 20) {
                        // 公式サイトリンク
                        Link(destination: URL(string: "https://miterundesu.jp")!) {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 20))
                                Text("miterundesu.jp")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }

                        // SNSリンク
                        HStack(spacing: 24) {
                            // X (Twitter)
                            Link(destination: URL(string: "https://twitter.com/miterundesu")!) {
                                VStack(spacing: 8) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 60)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                        )
                                    Text("X")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            // Instagram
                            Link(destination: URL(string: "https://instagram.com/miterundesu")!) {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 60)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                        )
                                    Text("Instagram")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }

                        // コピーライト
                        Text("© 2025 Miterundesu")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 40)
                }
            }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var bodyText: String {
        if settingsManager.isTheaterMode {
            return "このアプリは写真や映像を撮るためのものではありません。明るさを抑えた画面で、一時的に文字や作品を\"見やすく\"するために使用しています。保存・録画・共有は一切できません。周囲の方の迷惑にならないよう、光量を落として利用しています。"
        } else {
            return "ミテルンデスは、画像を保存・共有する機能を持たないアプリです。撮影ボタンを押しても写真は端末に保存されず、10分後に自動的に消去されます。プライバシーや著作権を守るための設計であり、あくまで\"見やすくするための補助ツール\"です。"
        }
    }
}

// MARK: - Normal Mode Illustrations
struct NormalModeIllustrations: View {
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                // 白杖を持つ人
                IllustrationCard(
                    icon: "figure.walk.motion",
                    label: "視覚支援",
                    description: "弱視の方の\n日常をサポート"
                )

                // 高齢者
                IllustrationCard(
                    icon: "figure.stand",
                    label: "老眼対応",
                    description: "小さな文字を\n拡大表示"
                )
            }
            .padding(.horizontal, 24)

            HStack(spacing: 16) {
                // 車椅子ユーザー
                IllustrationCard(
                    icon: "figure.roll",
                    label: "届かない場所",
                    description: "高い位置の\n確認に"
                )

                // スマホで拡大
                IllustrationCard(
                    icon: "iphone.gen3",
                    label: "拡大補助",
                    description: "棚の上の物を\n確認"
                )
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Theater Mode Illustrations
struct TheaterModeIllustrations: View {
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                // 映画館
                IllustrationCard(
                    icon: "movieclapper.fill",
                    label: "映画館",
                    description: "字幕を\n拡大表示",
                    backgroundColor: Color.white.opacity(0.15)
                )

                // 博物館
                IllustrationCard(
                    icon: "building.columns.fill",
                    label: "博物館",
                    description: "解説文を\n見やすく",
                    backgroundColor: Color.white.opacity(0.15)
                )
            }
            .padding(.horizontal, 24)

            HStack(spacing: 16) {
                // 美術館
                IllustrationCard(
                    icon: "paintpalette.fill",
                    label: "美術館",
                    description: "作品詳細を\n確認",
                    backgroundColor: Color.white.opacity(0.15)
                )

                // コンサートホール
                IllustrationCard(
                    icon: "music.note.house.fill",
                    label: "コンサート",
                    description: "歌詞・演目を\n表示",
                    backgroundColor: Color.white.opacity(0.15)
                )
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Illustration Card
struct IllustrationCard: View {
    let icon: String
    let label: String
    let description: String
    var backgroundColor: Color = Color.white.opacity(0.2)

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.white)
                .frame(height: 60)

            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
        )
    }
}

#Preview {
    ExplanationView(settingsManager: SettingsManager())
}

#Preview("Theater Mode") {
    let settingsManager = SettingsManager()
    settingsManager.isTheaterMode = true
    return ExplanationView(settingsManager: settingsManager)
}
