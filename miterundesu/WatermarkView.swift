//
//  WatermarkView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI
import UIKit

// MARK: - UIImage Extension for Watermark
extension UIImage {
    /// 画像にウォーターマークを焼き込む（画像データそのものを変更）
    func withWatermark(text: String, position: WatermarkPosition = .bottomLeft) -> UIImage {
        // 画像のサイズを取得
        let imageSize = self.size

        // レンダラーを作成（非推奨のUIGraphicsBeginImageContextを使わない）
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: UIGraphicsImageRendererFormat())

        let watermarkedImage = renderer.image { context in
            // 元の画像を描画
            self.draw(in: CGRect(origin: .zero, size: imageSize))

            // パディング設定
            let padding: CGFloat = imageSize.width * 0.015 // 画像幅の1.5%をパディング

            // 上段テキスト（アプリ名）のスタイル設定
            let titleFontSize: CGFloat = imageSize.width * 0.02 // 画像幅の2%
            let titleFont = UIFont.systemFont(ofSize: titleFontSize, weight: .bold)

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.4),
                .paragraphStyle: NSMutableParagraphStyle()
            ]

            // 下段テキスト（日付・ID）のスタイル設定
            let infoFontSize: CGFloat = imageSize.width * 0.015 // 画像幅の1.5%
            let infoFont = UIFont.monospacedSystemFont(ofSize: infoFontSize, weight: .medium)

            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: infoFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.35),
                .paragraphStyle: NSMutableParagraphStyle()
            ]

            // テキストを分割
            let titleText = "ミテルンデス"
            let infoText = text // "2025/01/10 15:30 | ID: ABC123" 形式

            // テキストサイズを計算
            let titleSize = titleText.size(withAttributes: titleAttributes)
            let infoSize = infoText.size(withAttributes: infoAttributes)

            // 全体の高さを計算
            let totalHeight = titleSize.height + infoSize.height + 2 // 2pxスペース

            // ウォーターマークの位置を計算
            let titleOrigin: CGPoint
            let infoOrigin: CGPoint

            switch position {
            case .bottomLeft:
                titleOrigin = CGPoint(
                    x: padding,
                    y: imageSize.height - totalHeight - padding
                )
                infoOrigin = CGPoint(
                    x: padding,
                    y: imageSize.height - infoSize.height - padding
                )
            case .bottomRight:
                titleOrigin = CGPoint(
                    x: imageSize.width - max(titleSize.width, infoSize.width) - padding,
                    y: imageSize.height - totalHeight - padding
                )
                infoOrigin = CGPoint(
                    x: imageSize.width - infoSize.width - padding,
                    y: imageSize.height - infoSize.height - padding
                )
            case .topLeft:
                titleOrigin = CGPoint(
                    x: padding,
                    y: padding
                )
                infoOrigin = CGPoint(
                    x: padding,
                    y: padding + titleSize.height + 2
                )
            case .topRight:
                titleOrigin = CGPoint(
                    x: imageSize.width - max(titleSize.width, infoSize.width) - padding,
                    y: padding
                )
                infoOrigin = CGPoint(
                    x: imageSize.width - infoSize.width - padding,
                    y: padding + titleSize.height + 2
                )
            }

            // テキストを描画（背景なし）
            titleText.draw(at: titleOrigin, withAttributes: titleAttributes)
            infoText.draw(at: infoOrigin, withAttributes: infoAttributes)
        }

        return watermarkedImage
    }

    /// ウォーターマークの位置
    enum WatermarkPosition {
        case topLeft, topRight, bottomLeft, bottomRight
    }
}

// MARK: - Watermark Helper
class WatermarkHelper {
    /// ウォーターマークテキストを生成（日付時間とデバイスIDのみ）
    static func generateWatermarkText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let dateString = dateFormatter.string(from: Date())

        let deviceID = generateShortDeviceID()

        return "\(dateString) | ID: \(deviceID)"
    }

    /// 短縮された端末IDを生成
    private static func generateShortDeviceID() -> String {
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
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

// MARK: - Watermark View
struct WatermarkView: View {
    @ObservedObject private var viewModel = WatermarkViewModel.shared
    let isDarkBackground: Bool

    init(isDarkBackground: Bool = true) {
        self.isDarkBackground = isDarkBackground
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            // 上段: アプリ名ロゴ
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 10)
                .opacity(0.4)
                .accessibilityHidden(true)

            // 下段: 日付時間とデバイスID
            Text(viewModel.watermarkInfo)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
                .accessibilityHidden(true)
        }
        .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 0.5)
        .accessibilityHidden(true)
    }
}

// MARK: - Watermark ViewModel
class WatermarkViewModel: ObservableObject {
    static let shared = WatermarkViewModel()

    @Published var watermarkInfo: String = ""
    private var timer: Timer?
    private let deviceID: String

    private init() {
        // 端末IDの短縮版を生成（最初の6文字）
        self.deviceID = WatermarkViewModel.generateShortDeviceID()
        updateWatermarkInfo()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    private func startTimer() {
        // 1分ごとに時刻を更新
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateWatermarkInfo()
        }
    }

    private func updateWatermarkInfo() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let dateString = dateFormatter.string(from: Date())

        watermarkInfo = "\(dateString) | ID: \(deviceID)"
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
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let padding = screenWidth * 0.04  // 4%

            ZStack(alignment: .bottomLeading) {
                content

                WatermarkView(isDarkBackground: isDarkBackground)
                    .padding(.leading, padding)
                    .padding(.bottom, padding)
                    .accessibilityHidden(true)
            }
        }
    }
}

extension View {
    /// 左下にウォーターマークを追加
    func watermark(isDarkBackground: Bool = true) -> some View {
        modifier(WatermarkOverlay(isDarkBackground: isDarkBackground))
    }
}
