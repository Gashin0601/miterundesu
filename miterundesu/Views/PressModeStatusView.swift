//
//  PressModeStatusView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

/// プレスモードの状態表示画面（期限切れ、未開始など）
struct PressModeStatusView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settingsManager: SettingsManager
    let device: PressDevice
    let contactEmail = "press@miterundesu.jp"

    var body: some View {
        NavigationView {
            ZStack {
                Color("MainGreen")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 20)

                        // ステータスアイコンとタイトル
                        VStack(spacing: 16) {
                            statusIcon
                                .font(.system(size: 70))
                                .foregroundColor(.white)

                            Text(statusTitle)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .accessibilityElement(children: .combine)

                        // メッセージカード
                        VStack(alignment: .leading, spacing: 16) {
                            Text(device.statusMessage)
                                .font(.body)
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)

                            Divider()
                                .background(.white.opacity(0.3))

                            // 所属情報
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "building.2")
                                        .foregroundColor(.white.opacity(0.7))
                                        .accessibilityHidden(true)
                                    Text(settingsManager.localizationManager.localizedString("press_mode_organization"))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Text(device.organization)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(settingsManager.localizationManager.localizedString("press_mode_organization")): \(device.organization)")
                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)

                        // 期限切れの場合：再申請案内
                        if device.status == .expired {
                            VStack(spacing: 16) {
                                Text(settingsManager.localizationManager.localizedString("press_mode_reapply"))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))

                                Button(action: {
                                    let deviceId = device.deviceId
                                    let subject = "プレスモード再申請"
                                    let body = """
                                    プレスモードの再申請を希望します。

                                    【情報】
                                    所属: \(device.organization)
                                    デバイスID: \(deviceId)
                                    前回の利用期間: \(device.periodDisplayString)

                                    【備考】

                                    """

                                    let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                    let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

                                    if let url = URL(string: "mailto:\(contactEmail)?subject=\(encodedSubject)&body=\(encodedBody)") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.fill")
                                            .font(.title3)
                                            .accessibilityHidden(true)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(settingsManager.localizationManager.localizedString("press_mode_reapply_button"))
                                                .font(.headline)
                                            Text(contactEmail)
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
                                .accessibilityLabel("\(settingsManager.localizationManager.localizedString("press_mode_reapply_button")): \(contactEmail)")
                                .padding(.horizontal, 24)
                            }
                        }

                        // 未開始の場合：開始日までの待機メッセージ
                        if device.status == .notStarted {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.7))
                                    .accessibilityHidden(true)

                                Text(settingsManager.localizationManager.localizedString("press_mode_wait_start"))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            .accessibilityElement(children: .combine)
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
                    .accessibilityLabel(settingsManager.localizationManager.localizedString("close"))
                }
            }
            .toolbarBackground(Color("MainGreen"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var statusIcon: Image {
        switch device.status {
        case .notStarted:
            return Image(systemName: "clock.badge.exclamationmark")
        case .active:
            return Image(systemName: "checkmark.circle.fill")
        case .expired:
            return Image(systemName: "clock.badge.xmark")
        case .deactivated:
            return Image(systemName: "xmark.shield")
        }
    }

    private var statusTitle: String {
        switch device.status {
        case .notStarted:
            return settingsManager.localizationManager.localizedString("press_mode_not_started")
        case .active:
            return settingsManager.localizationManager.localizedString("press_mode_active")
        case .expired:
            return settingsManager.localizationManager.localizedString("press_mode_expired")
        case .deactivated:
            return settingsManager.localizationManager.localizedString("press_mode_deactivated")
        }
    }
}

#Preview {
    let expiredDevice = PressDevice(
        id: UUID(),
        deviceId: "TEST-DEVICE",
        accessCode: "TEST2025",
        organization: "テスト新聞社",
        contactEmail: "test@example.com",
        contactName: "テスト太郎",
        startsAt: Date().addingTimeInterval(-365*24*60*60),
        expiresAt: Date().addingTimeInterval(-30*24*60*60),
        isActive: true,
        createdAt: Date(),
        updatedAt: Date(),
        notes: "テスト用"
    )

    return PressModeStatusView(settingsManager: SettingsManager(), device: expiredDevice)
}
