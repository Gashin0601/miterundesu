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
                        Text("プレスモードについて")
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
                                    Text("プレスモードとは")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                Text("報道機関の方が取材や撮影の際に、より便利にご利用いただけるモードです。")
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
                                    Text("ご利用対象者")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("新聞社・通信社")
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("テレビ局・ラジオ局")
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("雑誌・Web媒体")
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("その他報道機関")
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
                                    Text("ご利用申請")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                Text("プレスモードのご利用には事前申請が必要です。\n下記のデバイスIDと所属情報を添えて、お問い合わせください。")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)

                                // デバイスID表示
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("あなたのデバイスID")
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
                                                Text(showingDeviceIdCopied ? "コピー済み" : "コピー")
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
                            Text("プレスモード申請")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            Link(destination: URL(string: "https://miterundesu.jp/press")!) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.up.forward.square.fill")
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("詳細・申請フォーム")
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
                }
            }
            .toolbarBackground(Color("MainGreen"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    PressModeInfoView()
        .environmentObject(PressModeManager.shared)
}
