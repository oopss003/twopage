// 파일명: Coordinator.swift
// 기능:
// - 위치 서비스 활성화 및 권한 요청
// - 네이버 지도에 마커 표시
// - 현재 위치를 지도 중심으로 이동
// - 위치 오버레이 아이콘(파란 원) + 방향 빔(삼각형) 적용
// - 지도도 기기 방향에 맞춰 회전(.compass 모드)

import Foundation
import CoreLocation
import NMapsMap

class Coordinator: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = Coordinator()

    private let locationManager = CLLocationManager()
    private(set) var mapView = NMFMapView()
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()

        // 위치 매니저 설정
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()

        // 위치 오버레이 설정
        let overlay = mapView.locationOverlay

        // 🔵 실제 위치 원(크게)
        overlay.icon        = NMFOverlayImage(name: "loc_blue_dot")
        overlay.iconWidth   = 120   // 파란 원 크기
        overlay.iconHeight  = 120
        overlay.anchor      = CGPoint(x: 0.5, y: 0.5)

        // 🔵 방향 빔(작게)
        overlay.subIcon       = NMFOverlayImage(name: "loc_beam")
        overlay.subIconWidth  = 30
        overlay.subIconHeight = 30
        overlay.subAnchor     = CGPoint(x: 0.5, y: 0.65)

        // 정확도 원 숨김
        overlay.circleRadius = 0

        // 지도까지 회전(.compass)
        mapView.positionMode = .compass
    }

    // MARK: - 권한 확인
    func checkIfLocationServiceIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        } else {
            print("📍 위치 서비스가 꺼져 있습니다.")
        }
    }

    // MARK: - CLLocationManagerDelegate

    // 위치 좌표 업데이트
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        userLocation = latest.coordinate
    }

    // 방향(헤딩) 업데이트
    func locationManager(_ manager: CLLocationManager,
                         didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading
        if heading >= 0 {
            mapView.locationOverlay.heading = heading
            print("▶︎ Heading: \(heading)°")   // 디버그용 로그
        }
    }

    // 오류 처리
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("❌ 위치 업데이트 실패: \(error.localizedDescription)")
    }

    // MARK: - 지도 제어

    func updateMapWithLocation() {
        guard let loc = userLocation else {
            print("❗ 사용자 위치 없음")
            return
        }
        let latLng = NMGLatLng(lat: loc.latitude, lng: loc.longitude)
        let cameraUpdate = NMFCameraUpdate(scrollTo: latLng, zoomTo: 18)
        mapView.moveCamera(cameraUpdate)
        mapView.locationOverlay.location = latLng
    }

    // 마커 생성
    func setMarker(lat: Double, lng: Double, name: String) {
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: lat, lng: lng)
        marker.captionText = name
        marker.mapView = mapView
    }

    // NMFMapView 제공
    func getNaverMapView() -> NMFMapView {
        return mapView
    }
}

