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
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let horizontalPadding = screenWidth * 0.05  // 画面幅の5%
            let contentPadding = screenWidth * 0.06     // 画面幅の6%

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
                            .padding(.leading, horizontalPadding)

                            Spacer()

                            // 右：閉じるボタン
                            Button(action: {
                                dismiss()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                    Text(settingsManager.localizationManager.localizedString("close"))
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, horizontalPadding * 0.6)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.25))
                                )
                            }
                            .padding(.trailing, horizontalPadding)
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
                        .padding(.horizontal, contentPadding)

                    // 本文
                    Text(bodyText)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(8)
                        .padding(.horizontal, contentPadding)

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
                            .padding(.horizontal, contentPadding)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }

                        // SNSリンク
                        HStack(spacing: contentPadding * 0.4) {
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
            return "ミテルンデスは、撮影や録画ではなく、拡大鏡としてスマートフォンを使うためのアプリです。\n映画館や美術館、博物館など、静かな環境でも周囲に迷惑をかけずに「見る」ことを助けます。\n写真や動画を撮影することは一切できず、スクリーンショットや画面収録も無効化されています。"
        } else {
            return "ミテルンデスは、撮影や録画ではなく、拡大鏡としてスマートフォンを使うためのアプリです。\n弱視や老眼など、見えづらさを感じる方が安心して日常の中で「見る」ことをサポートします。\n撮影した画像は10分後に自動で削除され、スクリーンショットや画面収録もできません。"
        }
    }
}

// MARK: - Normal Mode Illustrations
struct NormalModeIllustrations: View {
    var body: some View {
        VStack(spacing: 24) {
            // イラスト1：商品棚の前でスマホを掲げる人（弱視）
            IllustrationCard(
                icon: "cart.fill",
                label: "見えづらい文字も、スマホで拡大。",
                description: "見えにくい商品ラベルや価格タグをスマホで拡大して確認します。周囲の明るさが強い店舗でも、スマホのカメラ拡大で文字を読み取りやすくできます。"
            )
            .padding(.horizontal, 24)

            // イラスト2：八百屋でスマホを使うおばあさん（老眼）
            IllustrationCard(
                icon: "leaf.fill",
                label: "小さな文字も、しっかり読める。",
                description: "細かい値札や産地表示をスマホで拡大し、眼鏡をかけ直さずに確認します。手元が見えづらいときも、少し離して見ることで楽に読めます。"
            )
            .padding(.horizontal, 24)

            // イラスト3：上の棚を見上げる代わりにスマホを掲げる人（車椅子ユーザー）
            IllustrationCard(
                icon: "figure.roll",
                label: "届かない場所も、見えるように。",
                description: "物理的に見えにくい高い場所を、スマホを掲げて拡大して確認します。商品棚の上部や掲示物なども、スマホを通して安全に見ることができます。"
            )
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Theater Mode Illustrations
struct TheaterModeIllustrations: View {
    var body: some View {
        VStack(spacing: 24) {
            // イラスト1：映画館の客席でスクリーンを拡大して見る人（弱視）
            IllustrationCard(
                icon: "movieclapper.fill",
                label: "映画の字幕を、もう少し大きく。",
                description: "見えづらい字幕や表情を、スマホのカメラで少し拡大して鑑賞します。光を最小限に抑えた画面で、周囲の邪魔にならずに映画を楽しめます。",
                backgroundColor: Color.white.opacity(0.15)
            )
            .padding(.horizontal, 24)

            // イラスト2：美術館で像と説明文を見るおばあさん（老眼）
            IllustrationCard(
                icon: "paintpalette.fill",
                label: "作品の説明も、はっきり読める。",
                description: "展示物のそばにある小さな文字や説明プレートを拡大して読みます。暗い照明の中でも、拡大表示で文字がはっきり見えます。",
                backgroundColor: Color.white.opacity(0.15)
            )
            .padding(.horizontal, 24)

            // イラスト3：ライブ会場で遠くのステージを拡大して見る若者
            IllustrationCard(
                icon: "music.mic.circle.fill",
                label: "遠くのステージも、近くに感じる。",
                description: "遠くのステージをスマホで一時的に拡大して、表情や演出を見やすくします。撮影や録画はできず、あくまで「見るためだけ」の拡大ツールとして利用します。",
                backgroundColor: Color.white.opacity(0.15)
            )
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)

                Text(label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }

            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
}

#Preview {
    ExplanationView(settingsManager: SettingsManager())
}

#Preview("Theater Mode") {
    let settingsManager = SettingsManager()
    settingsManager.isTheaterMode = true
    ExplanationView(settingsManager: settingsManager)
}
