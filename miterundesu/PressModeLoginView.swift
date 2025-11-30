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
    private let localizationManager = LocalizationManager.shared

    @State private var userId: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var loginAttempted: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background - アプリの統一背景色
                Color("MainGreen")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "newspaper.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)

                            Text(localizationManager.localizedString("press_login_title"))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text(localizationManager.localizedString("press_login_subtitle"))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)

                        // Login Form
                        VStack(spacing: 20) {
                            // User ID Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text(localizationManager.localizedString("press_login_user_id"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)

                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)

                                    TextField(localizationManager.localizedString("press_login_user_id_placeholder"), text: $userId)
                                        .textContentType(.username)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(10)
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text(localizationManager.localizedString("press_login_password"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)

                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)

                                    if showPassword {
                                        TextField(localizationManager.localizedString("press_login_password_placeholder"), text: $password)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .foregroundColor(.white)
                                    } else {
                                        SecureField(localizationManager.localizedString("press_login_password_placeholder"), text: $password)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .foregroundColor(.white)
                                    }

                                    Button(action: {
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(10)
                            }

                            // Error Message
                            if let error = pressModeManager.error, loginAttempted {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.yellow)
                                    Text(error)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.3))
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
                                        Text(localizationManager.localizedString("press_login_button"))
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(canLogin ? Color.white : Color.white.opacity(0.3))
                                .foregroundColor(canLogin ? Color("MainGreen") : .white.opacity(0.5))
                                .cornerRadius(12)
                            }
                            .disabled(!canLogin || pressModeManager.isLoading)
                        }
                        .padding(.horizontal, 24)

                        // Info Section
                        VStack(spacing: 16) {
                            Divider()
                                .background(.white.opacity(0.3))

                            VStack(alignment: .leading, spacing: 12) {
                                Label(localizationManager.localizedString("press_login_info_title"), systemImage: "info.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(localizationManager.localizedString("press_login_info_description"))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))

                                Text(localizationManager.localizedString("press_login_info_apply"))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.15))
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: UIScreen.main.bounds.width * 0.07))
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color("MainGreen"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
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
