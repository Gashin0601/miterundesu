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
        VStack(spacing: 32) {
            // 3つのアイコンを横に並べる
            HStack(spacing: 20) {
                IconColumn(
                    icon: "cart.fill",
                    title: "商品を確認"
                )
                IconColumn(
                    icon: "doc.text.magnifyingglass",
                    title: "文字を拡大"
                )
                IconColumn(
                    icon: "figure.roll",
                    title: "高い場所も"
                )
            }
            .padding(.horizontal, 24)

            // 各アイコンの説明
            VStack(spacing: 24) {
                ExplanationItem(
                    subtitle: "弱視・老眼の人",
                    description: "見えにくい商品ラベルや価格タグをスマホで拡大して確認。周囲の明るさが強い店舗でも、カメラ拡大で文字を読み取りやすくできます。"
                )

                ExplanationItem(
                    subtitle: "見えづらい方",
                    description: "細かい値札や産地表示をスマホで拡大し、眼鏡をかけ直さずに確認。手元が見えづらいときも、少し離して見ることで楽に読めます。"
                )

                ExplanationItem(
                    subtitle: "車椅子の方",
                    description: "物理的に見えにくい高い場所を、スマホを掲げて拡大して確認。商品棚の上部や掲示物なども、スマホを通して安全に見ることができます。"
                )
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Theater Mode Illustrations
struct TheaterModeIllustrations: View {
    var body: some View {
        VStack(spacing: 32) {
            // 3つのアイコンを横に並べる
            HStack(spacing: 20) {
                IconColumn(
                    icon: "movieclapper.fill",
                    title: "字幕を見る"
                )
                IconColumn(
                    icon: "paintpalette.fill",
                    title: "作品解説"
                )
                IconColumn(
                    icon: "music.mic.circle.fill",
                    title: "遠くを見る"
                )
            }
            .padding(.horizontal, 24)

            // 各アイコンの説明
            VStack(spacing: 24) {
                ExplanationItem(
                    subtitle: "弱視の方",
                    description: "見えづらい字幕や表情を、スマホのカメラで少し拡大して鑑賞。光を最小限に抑えた画面で、周囲の邪魔にならずに映画を楽しめます。"
                )

                ExplanationItem(
                    subtitle: "老眼の方",
                    description: "展示物のそばにある小さな文字や説明プレートを拡大して読みます。暗い照明の中でも、拡大表示で文字がはっきり見えます。"
                )

                ExplanationItem(
                    subtitle: "後方席の方",
                    description: "遠くのステージをスマホで一時的に拡大して、表情や演出を見やすくします。撮影や録画はできず、あくまで「見るためだけ」の拡大ツールです。"
                )
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Icon Column (アイコンとタイトル)
struct IconColumn: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )

            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Explanation Item (サブタイトルと説明文)
struct ExplanationItem: View {
    let subtitle: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(subtitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
        )
    }
}

struct ExplanationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExplanationView(settingsManager: SettingsManager())
                .previewDisplayName("Normal Mode")

            ExplanationView(settingsManager: {
                let manager = SettingsManager()
                manager.isTheaterMode = true
                return manager
            }())
            .previewDisplayName("Theater Mode")
        }
    }
}
