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

            // 上部：閉じるボタンと残り時間
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                    .padding()

                    Spacer()

                    // 残り時間表示
                    Text(formattedRemainingTime)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.7))
                        )
                        .padding()
                }

                Spacer()

                // 下部：拡大率表示
                if scale > 1 {
                    Text("×\(String(format: "%.1f", scale))")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.5))
                        )
                        .padding(.bottom, 40)
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

    private var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
