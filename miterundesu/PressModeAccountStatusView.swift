//
//  PressModeAccountStatusView.swift
//  miterundesu
//
//  Created by Claude Code
//  Displays press account status information
//

import SwiftUI

struct PressModeAccountStatusView: View {
    let settingsManager: SettingsManager
    let account: PressAccount
    @Environment(\.dismiss) private var dismiss
    private let localizationManager = LocalizationManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Status Icon
                        statusIcon
                            .font(.system(size: 80))
                            .padding(.top, 40)

                        // Status Message
                        VStack(spacing: 12) {
                            Text(statusTitle)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text(account.statusMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // Account Information
                        VStack(spacing: 16) {
                            Divider()

                            VStack(alignment: .leading, spacing: 12) {
                                Label(localizationManager.localizedString("press_account_info"), systemImage: "info.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.blue)

                                infoRow(label: localizationManager.localizedString("press_account_user_id"), value: account.userId)
                                infoRow(label: localizationManager.localizedString("press_account_organization"), value: account.organizationName)

                                if let contact = account.contactPerson {
                                    infoRow(label: localizationManager.localizedString("press_account_contact"), value: contact)
                                }

                                infoRow(label: localizationManager.localizedString("press_account_expiration"), value: account.expirationDisplayString)

                                if let approvedAt = account.approvalDisplayString {
                                    infoRow(label: localizationManager.localizedString("press_account_approved_at"), value: approvedAt)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)

                        // Action Button
                        if account.status == .expired {
                            VStack(spacing: 12) {
                                Text(localizationManager.localizedString("press_account_expired_message"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)

                                Link(destination: URL(string: "https://miterundesu.jp/press")!) {
                                    HStack {
                                        Image(systemName: "arrow.up.right.square")
                                        Text(localizationManager.localizedString("press_account_apply_page"))
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 24)
                            }
                        }

                        Spacer()
                    }
                }
            }
            .navigationTitle(localizationManager.localizedString("press_account_status_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString("close")) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var statusIcon: some View {
        Group {
            switch account.status {
            case .active:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .expired:
                Image(systemName: "clock.badge.xmark")
                    .foregroundColor(.orange)
            case .deactivated:
                Image(systemName: "xmark.shield")
                    .foregroundColor(.red)
            }
        }
    }

    private var statusTitle: String {
        switch account.status {
        case .active:
            return localizationManager.localizedString("press_account_status_active")
        case .expired:
            return localizationManager.localizedString("press_account_status_expired")
        case .deactivated:
            return localizationManager.localizedString("press_account_status_deactivated")
        }
    }

    // MARK: - Helper Views

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview {
    let sampleAccount = PressAccount(
        id: UUID(),
        userId: "sample-user",
        organizationName: "Sample News",
        organizationType: "newspaper",
        contactPerson: "田中太郎",
        email: "tanaka@example.com",
        phone: nil,
        approvedBy: "System",
        approvedAt: Date(),
        expiresAt: Date().addingTimeInterval(-86400), // Yesterday
        isActive: true,
        lastLoginAt: Date(),
        createdAt: Date(),
        updatedAt: Date()
    )

    return PressModeAccountStatusView(
        settingsManager: SettingsManager(),
        account: sampleAccount
    )
}
