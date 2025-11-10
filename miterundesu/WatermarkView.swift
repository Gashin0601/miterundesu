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

            // ウォーターマークテキストのスタイル設定
            let fontSize: CGFloat = imageSize.width * 0.025 // 画像幅の2.5%
            let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .medium)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(0.7),
                .backgroundColor: UIColor.black.withAlphaComponent(0.4),
                .paragraphStyle: paragraphStyle
            ]

            // テキストサイズを計算
            let textSize = text.size(withAttributes: attributes)

            // ウォーターマークの位置を計算
            let padding: CGFloat = imageSize.width * 0.02 // 画像幅の2%をパディング
            let textOrigin: CGPoint

            switch position {
            case .bottomLeft:
                textOrigin = CGPoint(
                    x: padding,
                    y: imageSize.height - textSize.height - padding
                )
            case .bottomRight:
                textOrigin = CGPoint(
                    x: imageSize.width - textSize.width - padding,
                    y: imageSize.height - textSize.height - padding
                )
            case .topLeft:
                textOrigin = CGPoint(
                    x: padding,
                    y: padding
                )
            case .topRight:
                textOrigin = CGPoint(
                    x: imageSize.width - textSize.width - padding,
                    y: padding
                )
            }

            // テキストを描画
            let textRect = CGRect(origin: textOrigin, size: textSize)
            text.draw(in: textRect, withAttributes: attributes)
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
    /// ウォーターマークテキストを生成
    static func generateWatermarkText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let dateString = dateFormatter.string(from: Date())

        let deviceID = generateShortDeviceID()

        return "miterundesu  |  \(dateString)  |  ID: \(deviceID)"
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
    @StateObject private var viewModel = WatermarkViewModel()
    let isDarkBackground: Bool

    init(isDarkBackground: Bool = true) {
        self.isDarkBackground = isDarkBackground
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.watermarkText)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(isDarkBackground ? .white : .black)
                .opacity(0.9) // 視認性向上
                .shadow(color: isDarkBackground ? .black.opacity(0.8) : .white.opacity(0.8), radius: 3, x: 0, y: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDarkBackground ? Color.black.opacity(0.5) : Color.white.opacity(0.5)) // 背景を濃く
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
