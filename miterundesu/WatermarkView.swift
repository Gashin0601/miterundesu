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

            // 水のような透明感のある属性
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(0.85), // より透明に
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
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 0) // 水のような光沢
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            // グラスモーフィズム効果（水のような透明感）
            ZStack {
                // 半透明のグラデーション背景（水滴のような）
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.25),
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // 薄いブラーオーバーレイ（フロストガラス効果）
                Color.white.opacity(0.1)
            }
            .background(.ultraThinMaterial) // SwiftUIのMaterial（水のようなぼかし）
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4) // 水のような影
        }
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
