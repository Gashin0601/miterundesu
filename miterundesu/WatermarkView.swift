//
//  WatermarkView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import UIKit

// MARK: - Watermark View
struct WatermarkView: View {
    @StateObject private var viewModel = WatermarkViewModel()
    let isDarkBackground: Bool

    init(isDarkBackground: Bool = true) {
        self.isDarkBackground = isDarkBackground
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.watermarkText)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(isDarkBackground ? .white : .black)
                .opacity(0.6)
                .shadow(color: isDarkBackground ? .black.opacity(0.5) : .white.opacity(0.5), radius: 2, x: 0, y: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isDarkBackground ? Color.black.opacity(0.3) : Color.white.opacity(0.3))
        )
    }
}

// MARK: - Watermark ViewModel
class WatermarkViewModel: ObservableObject {
    @Published var watermarkText: String = ""
    private var timer: Timer?
    private let deviceID: String

    init() {
        // 端末IDの短縮版を生成（最初の6文字）
        self.deviceID = WatermarkViewModel.generateShortDeviceID()
        updateWatermarkText()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    private func startTimer() {
        // 1分ごとに時刻を更新
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateWatermarkText()
        }
    }

    private func updateWatermarkText() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let dateString = dateFormatter.string(from: Date())

        watermarkText = "miterundesu  |  \(dateString)  |  ID: \(deviceID)"
    }

    private static func generateShortDeviceID() -> String {
        // UIDevice.current.identifierForVendorを使用
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            // UUIDから最初の6文字を取得（ハイフンを除く）
            let alphanumeric = uuid.replacingOccurrences(of: "-", with: "")
            let shortID = String(alphanumeric.prefix(6)).uppercased()
            return shortID
        }

        // フォールバック：ランダムな6文字
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomID = String((0..<6).map { _ in characters.randomElement()! })
        return randomID
    }
}

// MARK: - Watermark Overlay Modifier
struct WatermarkOverlay: ViewModifier {
    let isDarkBackground: Bool

    func body(content: Content) -> some View {
        ZStack(alignment: .bottomLeading) {
            content

            WatermarkView(isDarkBackground: isDarkBackground)
                .padding(.leading, 16)
                .padding(.bottom, 16)
        }
    }
}

extension View {
    /// 左下にウォーターマークを追加
    func watermark(isDarkBackground: Bool = true) -> some View {
        modifier(WatermarkOverlay(isDarkBackground: isDarkBackground))
    }
}
