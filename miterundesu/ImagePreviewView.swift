//
//  ImagePreviewView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

struct ImagePreviewView: View {
    let capturedImage: CapturedImage
    @Environment(\.dismiss) var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    @State private var remainingTime: TimeInterval

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(capturedImage: CapturedImage) {
        self.capturedImage = capturedImage
        _remainingTime = State(initialValue: capturedImage.remainingTime)
    }

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let buttonSize = screenWidth * 0.08        // 8%
            let buttonPadding = screenWidth * 0.04     // 4%
            let textHorizontalPadding = screenWidth * 0.03  // 3%
            let textVerticalPadding = screenWidth * 0.02    // 2%
            let cornerRadius = screenWidth * 0.025     // 2.5%
            let bottomPadding = screenWidth * 0.1      // 10%

            ZStack {
                Color.black.ignoresSafeArea()

                // 画像表示（ズーム・ドラッグ可能）
                Image(uiImage: capturedImage.image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 1), 10)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .allowsHitTesting(true)
                    .contentShape(Rectangle())
                    // 長押しジェスチャーを無効化（画像保存を防ぐ）
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                // 何もしない（長押しを無効化）
                            }
                    )
                    // コンテキストメニューを無効化（共有・保存を防ぐ）
                    .contextMenu { }

                // 上部：閉じるボタンと残り時間
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: buttonSize))
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                        .padding(buttonPadding)

                        Spacer()

                        // 残り時間表示
                        Text(formattedRemainingTime)
                            .font(.system(size: screenWidth * 0.035, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, textHorizontalPadding)
                            .padding(.vertical, textVerticalPadding)
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(Color.red.opacity(0.7))
                            )
                            .padding(buttonPadding)
                    }

                    Spacer()

                    // 下部：拡大率表示
                    if scale > 1 {
                        Text("×\(String(format: "%.1f", scale))")
                            .font(.system(size: screenWidth * 0.04, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, textHorizontalPadding)
                            .padding(.vertical, textVerticalPadding)
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(Color.black.opacity(0.5))
                            )
                            .padding(.bottom, bottomPadding)
                    }
                }
            }
            .onReceive(timer) { _ in
                remainingTime = capturedImage.remainingTime
                if remainingTime <= 0 {
                    dismiss()
                }
            }
        }
    }

    private var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
