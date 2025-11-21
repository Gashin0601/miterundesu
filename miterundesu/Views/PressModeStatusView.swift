//
//  PressModeStatusView.swift
//  miterundesu
//
//  DEPRECATED: This view is no longer used in the new authentication system.
//  Kept for compatibility only. Use PressModeAccountStatusView instead.
//

import SwiftUI

/// 旧プレスモード状態表示画面（非推奨）
/// 新システムではPressModeAccountStatusViewを使用してください
@available(*, deprecated, message: "Use PressModeAccountStatusView instead")
struct PressModeStatusView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settingsManager: SettingsManager
    let device: PressDevice

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding()

                Text("この画面は非推奨です")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()

                Text("新しい認証システムではアカウント状態表示画面を使用してください。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()
            }
            .navigationTitle("非推奨")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let expiredDevice = PressDevice(
        id: UUID(),
        deviceId: "test-device",
        accessCode: "test-code",
        organization: "Test Org",
        contactEmail: "test@example.com",
        contactName: "Test User",
        startsAt: Date().addingTimeInterval(-86400 * 30),
        expiresAt: Date().addingTimeInterval(-86400),
        isActive: true,
        createdAt: Date(),
        updatedAt: Date(),
        notes: nil
    )

    return PressModeStatusView(
        settingsManager: SettingsManager(),
        device: expiredDevice
    )
}
