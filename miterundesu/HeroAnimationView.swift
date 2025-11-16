//
//  HeroAnimationView.swift
//  miterundesu
//
//  Created by Claude Code
//

import SwiftUI

struct HeroAnimationView: View {
    @State private var phoneScale: CGFloat = 0.3
    @State private var phoneRotation: Double = -10
    @State private var phoneOpacity: Double = 0

    @State private var topLeftScale: CGFloat = 0
    @State private var topLeftOffset: CGSize = .zero
    @State private var topLeftRotation: Double = 0
    @State private var topLeftOpacity: Double = 0

    @State private var topRightScale: CGFloat = 0
    @State private var topRightOffset: CGSize = .zero
    @State private var topRightRotation: Double = 0
    @State private var topRightOpacity: Double = 0

    @State private var bottomLeftScale: CGFloat = 0
    @State private var bottomLeftOffset: CGSize = .zero
    @State private var bottomLeftRotation: Double = 0
    @State private var bottomLeftOpacity: Double = 0

    @State private var bottomRightScale: CGFloat = 0
    @State private var bottomRightOffset: CGSize = .zero
    @State private var bottomRightRotation: Double = 0
    @State private var bottomRightOpacity: Double = 0

    let buildingSize: CGFloat = 62

    var body: some View {
        ZStack {
            // Central phone
            Image("hand-phone")
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .scaleEffect(phoneScale)
                .rotationEffect(.degrees(phoneRotation))
                .opacity(phoneOpacity)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

            // Buildings positioned around the phone
            // Top-left: Convenience store
            Image("building-convenience")
                .resizable()
                .scaledToFit()
                .frame(width: buildingSize, height: buildingSize)
                .scaleEffect(topLeftScale)
                .rotationEffect(.degrees(topLeftRotation))
                .opacity(topLeftOpacity)
                .offset(topLeftOffset)

            // Top-right: Supermarket
            Image("building-supermarket")
                .resizable()
                .scaledToFit()
                .frame(width: buildingSize, height: buildingSize)
                .scaleEffect(topRightScale)
                .rotationEffect(.degrees(topRightRotation))
                .opacity(topRightOpacity)
                .offset(topRightOffset)

            // Bottom-left: Museum
            Image("building-museum")
                .resizable()
                .scaledToFit()
                .frame(width: buildingSize, height: buildingSize)
                .scaleEffect(bottomLeftScale)
                .rotationEffect(.degrees(bottomLeftRotation))
                .opacity(bottomLeftOpacity)
                .offset(bottomLeftOffset)

            // Bottom-right: Theater
            Image("building-theater")
                .resizable()
                .scaledToFit()
                .frame(width: buildingSize, height: buildingSize)
                .scaleEffect(bottomRightScale)
                .rotationEffect(.degrees(bottomRightRotation))
                .opacity(bottomRightOpacity)
                .offset(bottomRightOffset)
        }
        .frame(width: 300, height: 300)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Phone entrance animation - starts immediately
        withAnimation(.easeOut(duration: 1.0)) {
            phoneScale = 1.0
            phoneRotation = 0
            phoneOpacity = 1.0
        }

        // Building animations with delays
        // Spring animation to match cubic-bezier(0.34, 1.56, 0.64, 1)
        let springAnimation = Animation.interpolatingSpring(
            mass: 0.8,
            stiffness: 100,
            damping: 10,
            initialVelocity: 0
        )

        // Top-left building (delay: 1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(springAnimation.delay(0).speed(1.4)) {
                topLeftScale = 1.0
                topLeftOffset = CGSize(width: -108, height: -84) // Scale adjusted for mobile
                topLeftRotation = 0
                topLeftOpacity = 1.0
            }
        }

        // Top-right building (delay: 1.35s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation(springAnimation.delay(0).speed(1.4)) {
                topRightScale = 1.0
                topRightOffset = CGSize(width: 108, height: -84)
                topRightRotation = 0
                topRightOpacity = 1.0
            }
        }

        // Bottom-left building (delay: 1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(springAnimation.delay(0).speed(1.4)) {
                bottomLeftScale = 1.0
                bottomLeftOffset = CGSize(width: -108, height: 84)
                bottomLeftRotation = 0
                bottomLeftOpacity = 1.0
            }
        }

        // Bottom-right building (delay: 1.65s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
            withAnimation(springAnimation.delay(0).speed(1.4)) {
                bottomRightScale = 1.0
                bottomRightOffset = CGSize(width: 108, height: 84)
                bottomRightRotation = 0
                bottomRightOpacity = 1.0
            }
        }
    }
}

// MARK: - Preview
struct HeroAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color("MainGreen")
                .ignoresSafeArea()
            HeroAnimationView()
        }
    }
}
