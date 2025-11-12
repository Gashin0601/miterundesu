//
//  PressModeAccessView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import Supabase

/// プレスモードのアクセスコード入力画面
struct PressModeAccessView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPressMode: Bool
    let targetState: Bool // オンにしようとしているかオフにしようとしているか

    @State private var accessCode: String = ""
    @State private var showError: Bool = false
    @State private var isVerifying: Bool = false
    @State private var errorMessage: String = "アクセスコードが正しくありません"

    private let contactEmail = "press@miterundesu.jp"

    var body: some View {
        NavigationView {
            ZStack {
                Color("MainGreen")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // アイコン
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    // タイトル
                    Text("プレスモード\(targetState ? "有効化" : "無効化")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // 説明文
                    VStack(spacing: 12) {
                        Text("プレスモードを\(targetState ? "有効にする" : "無効にする")には、\nアクセスコードが必要です。")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)

                        Text("アクセスコードをお持ちでない場合は、\n下記までお問い合わせください。")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 32)

                    // アクセスコード入力
                    VStack(spacing: 16) {
                        SecureField("アクセスコードを入力", text: $accessCode)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .textContentType(.oneTimeCode)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .onChange(of: accessCode) { _, _ in
                                showError = false
                            }

                        if showError {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text(errorMessage)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 32)

                    // 確認ボタン
                    Button(action: {
                        verifyAccessCode()
                    }) {
                        HStack {
                            if isVerifying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isVerifying ? "確認中..." : "確認")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(accessCode.isEmpty ? 0.3 : 0.9))
                        .foregroundColor(Color("MainGreen"))
                        .cornerRadius(12)
                    }
                    .disabled(accessCode.isEmpty || isVerifying)
                    .padding(.horizontal, 32)

                    Spacer()

                    // 連絡先
                    VStack(spacing: 8) {
                        Text("お問い合わせ")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))

                        Button(action: {
                            if let url = URL(string: "mailto:\(contactEmail)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "envelope.fill")
                                Text(contactEmail)
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.bottom, 32)
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

    private func verifyAccessCode() {
        isVerifying = true
        showError = false

        Task {
            do {
                // Supabaseからアクセスコードを検証
                let response: [PressAccessCode] = try await supabase
                    .from("press_access_codes")
                    .select()
                    .eq("code", value: accessCode.uppercased())
                    .eq("is_active", value: true)
                    .limit(1)
                    .execute()
                    .value

                await MainActor.run {
                    if response.first != nil {
                        // アクセスコードが正しい
                        isPressMode = targetState
                        dismiss()
                    } else {
                        // アクセスコードが間違っている
                        errorMessage = "アクセスコードが正しくありません"
                        showError = true
                        // エラー時にバイブレーション
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    }
                    isVerifying = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "ネットワークエラーが発生しました"
                    showError = true
                    isVerifying = false
                    // エラー時にバイブレーション
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
}

// アクセスコードモデル
struct PressAccessCode: Codable {
    let id: UUID
    let code: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case isActive = "is_active"
    }
}

#Preview {
    PressModeAccessView(isPressMode: .constant(false), targetState: true)
}
