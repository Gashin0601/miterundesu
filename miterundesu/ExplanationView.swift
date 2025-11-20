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
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)

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
                                        .accessibilityHidden(true)
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
                            .accessibilityLabel(settingsManager.localizationManager.localizedString("close"))
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
                                    .accessibilityHidden(true)
                                Text("miterundesu.jp")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                        }
                        .accessibilityLabel("公式サイト: miterundesu.jp")
                        .accessibilityHint("リンクを開く")

                        // SNSリンク
                        HStack(spacing: contentPadding * 0.4) {
                            // X (Twitter)
                            Link(destination: URL(string: "https://x.com/miterundesu_jp?s=11")!) {
                                XLogoIcon()
                                    .frame(width: 50, height: 50)
                            }

                            // Instagram
                            Link(destination: URL(string: "https://www.instagram.com/miterundesu_jp/?utm_source=ig_web_button_share_sheet")!) {
                                InstagramLogoIcon()
                                    .frame(width: 50, height: 50)
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
            return "ミテルンデスは、撮影や録画を目的とせず、\"見るためだけ\"に使えるカメラアプリです。\n映画館・美術館・博物館など、撮影が禁止されている場所でも、安心して\"拡大して見る\"ことができます。\n\nアプリでは写真・動画の撮影は完全に不可。\nさらに、スクリーンショットや画面収録も無効化されており、安心してご利用いただけます。"
        } else {
            return "ミテルンデスは、撮影や録画ではなく、拡大鏡としてスマートフォンを使うためのアプリです。\n弱視や老眼など、見えづらさを感じる方が安心して日常の中で「見る」ことをサポートします。\n撮影した画像は10分後に自動で削除され、スクリーンショットや画面収録もできません。"
        }
    }
}

// MARK: - Normal Mode Illustrations
struct NormalModeIllustrations: View {
    var body: some View {
        VStack(spacing: 32) {
            // 2つのアイコンを横に並べる
            HStack(spacing: 40) {
                Image("icon-white-cane")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                Image("icon-wheelchair")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            }
            .padding(.horizontal, 24)

            // 各アイコンの説明
            VStack(spacing: 24) {
                ExplanationItem(
                    subtitle: "見えづらい方（弱視・老眼）",
                    description: "コンビニやスーパーでは、店内撮影を禁止する貼り紙が増えてきています。\nしかし、商品をしっかり確認するためには、スマートフォンで\"拡大して見る\"ことが必要な場面があります。"
                )

                ExplanationItem(
                    subtitle: "車椅子ユーザー",
                    description: "棚が高く、商品が目の高さに入らないことがあります。\nそのため、手を伸ばして写真を撮り、拡大して確認する必要があるのです。"
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
            // 2つのアイコンを横に並べる
            HStack(spacing: 40) {
                Image("building-theater")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                Image("building-museum")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            }
            .padding(.horizontal, 24)

            // 各アイコンの説明
            VStack(spacing: 24) {
                ExplanationItem(
                    subtitle: "映画館",
                    description: "字幕や表情が見えづらいとき、スマホのカメラで必要な部分だけ少し拡大して鑑賞できます。\n画面の光は最小限に抑えられるため、周囲の迷惑にならず映画を楽しめます。"
                )

                ExplanationItem(
                    subtitle: "美術館・博物館",
                    description: "展示物のそばにある細かな文字や説明プレートを拡大して読みやすくできます。\n照明が暗い展示室でも、拡大表示によって文字をはっきり確認できます。"
                )
            }
            .padding(.horizontal, 24)
        }
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
    }
}

// MARK: - X Logo Icon
struct XLogoIcon: View {
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            Path { path in
                // X logo の形状（公式ロゴに近い形）
                // 左上から右下への太い斜線
                path.move(to: CGPoint(x: size.width * 0.15, y: size.height * 0.15))
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.5))
                path.addLine(to: CGPoint(x: size.width * 0.85, y: size.height * 0.85))

                path.move(to: CGPoint(x: size.width * 0.15, y: size.height * 0.15))
                path.addLine(to: CGPoint(x: size.width * 0.27, y: size.height * 0.15))
                path.addLine(to: CGPoint(x: size.width * 0.85, y: size.height * 0.85))
                path.addLine(to: CGPoint(x: size.width * 0.73, y: size.height * 0.85))
                path.closeSubpath()

                // 右上から左下への太い斜線
                path.move(to: CGPoint(x: size.width * 0.85, y: size.height * 0.15))
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.5))
                path.addLine(to: CGPoint(x: size.width * 0.15, y: size.height * 0.85))

                path.move(to: CGPoint(x: size.width * 0.85, y: size.height * 0.15))
                path.addLine(to: CGPoint(x: size.width * 0.73, y: size.height * 0.15))
                path.addLine(to: CGPoint(x: size.width * 0.15, y: size.height * 0.85))
                path.addLine(to: CGPoint(x: size.width * 0.27, y: size.height * 0.85))
                path.closeSubpath()
            }
            .fill(Color.white)
        }
    }
}

// MARK: - Instagram Logo Icon
struct InstagramLogoIcon: View {
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // Instagram カメラアイコン風
                RoundedRectangle(cornerRadius: size.width * 0.24)
                    .stroke(Color.white, lineWidth: size.width * 0.06)
                    .padding(size.width * 0.08)

                Circle()
                    .stroke(Color.white, lineWidth: size.width * 0.06)
                    .frame(width: size.width * 0.48, height: size.width * 0.48)

                Circle()
                    .fill(Color.white)
                    .frame(width: size.width * 0.08, height: size.width * 0.08)
                    .offset(x: size.width * 0.24, y: -size.width * 0.24)
            }
        }
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
