//
//  miterundesuApp.swift
//  miterundesu
//
//  Created by 鈴木我信 on 2025/11/09.
//

import SwiftUI

// AppDelegateで画面向きを制御
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait

    func application(_ application: UIApplication,
                    supportedInterfaceOrientationsFor window: UIWindow?)
                    -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

@main
struct miterundesuApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                // アプリがバックグラウンドに移行した際の処理
                handleAppBackground()
            case .inactive:
                // アプリが非アクティブになった際の処理
                handleAppInactive()
            case .active:
                // アプリがアクティブになった際の処理
                break
            @unknown default:
                break
            }
        }
    }

    private func handleAppBackground() {
        // バックグラウンド移行時にセキュリティ処理を実行
        print("🔒 アプリがバックグラウンドに移行しました - セキュリティ処理を実行")
        // 注: ここでは通知を送信して、ContentViewでメモリクリアを実行させる
        NotificationCenter.default.post(name: NSNotification.Name("AppWillResignActive"), object: nil)
    }

    private func handleAppInactive() {
        // 非アクティブ時の処理（必要に応じて）
        print("⏸️ アプリが非アクティブになりました")
    }
}
