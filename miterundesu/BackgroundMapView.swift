//
//  BackgroundMapView.swift
//  miterundesu
//
//  Created by Claude Code
//
//  通常モードで背景に薄く表示するマップ

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Equatable Location Wrapper
/// CLLocationCoordinate2DをEquatableにするためのラッパー
struct EquatableLocation: Equatable {
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: EquatableLocation, rhs: EquatableLocation) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()
    @Published var currentLocation: EquatableLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = EquatableLocation(coordinate: location.coordinate)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdating()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("📍 Location error: \(error.localizedDescription)")
        #endif
    }
}

// MARK: - Background Map View
struct BackgroundMapView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            // 現在地マーカー
            if let location = locationManager.currentLocation {
                Marker("", coordinate: location.coordinate)
                    .tint(.blue)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .allowsHitTesting(false) // タッチイベントを無効化
        .opacity(0.3) // 薄く表示
        .onAppear {
            locationManager.requestPermission()
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if let location = newLocation {
                withAnimation(.easeInOut(duration: 1.0)) {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    BackgroundMapView()
}
