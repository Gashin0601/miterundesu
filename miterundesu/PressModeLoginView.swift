//
//  PressModeLoginView.swift
//  miterundesu
//
//  Created by Claude Code
//  Login view for Press Mode authentication
//

import SwiftUI

struct PressModeLoginView: View {
    @StateObject private var pressModeManager = PressModeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var userId: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var loginAttempted: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "newspaper.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("プレスモードログイン")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("取材用アカウントでログインしてください")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)

                        // Login Form
                        VStack(spacing: 20) {
                            // User ID Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ユーザーID")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)

                                    TextField("ユーザーIDを入力", text: $userId)
                                        .textContentType(.username)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("パスワード")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)

                                    if showPassword {
                                        TextField("パスワードを入力", text: $password)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                    } else {
                                        SecureField("パスワードを入力", text: $password)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                    }

                                    Button(action: {
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }

                            // Error Message
                            if let error = pressModeManager.error, loginAttempted {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }

                            // Login Button
                            Button(action: {
                                Task {
                                    await performLogin()
                                }
                            }) {
                                HStack {
                                    if pressModeManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "person.badge.key.fill")
                                        Text("ログイン")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(canLogin ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!canLogin || pressModeManager.isLoading)
                        }
                        .padding(.horizontal, 24)

                        // Info Section
                        VStack(spacing: 16) {
                            Divider()

                            VStack(alignment: .leading, spacing: 12) {
                                Label("取材用アカウントについて", systemImage: "info.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.blue)

                                Text("プレスモードは、報道機関の方々が取材活動で本アプリを使用する際の専用機能です。")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text("アカウントをお持ちでない場合は、公式ウェブサイトから申請してください。")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var canLogin: Bool {
        !userId.isEmpty && !password.isEmpty
    }

    // MARK: - Methods

    private func performLogin() async {
        loginAttempted = true

        let success = await pressModeManager.login(userId: userId, password: password)

        if success {
            // ログイン成功 - 画面を閉じる
            await MainActor.run {
                dismiss()
            }
        }
    }
}

#Preview {
    PressModeLoginView()
}
