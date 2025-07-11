// 파일명: Coordinator.swift
// 기능:
// - 위치 서비스 활성화 및 권한 요청
// - 네이버 지도에 마커 표시
// - 현재 위치를 지도 중심으로 이동
// 관련 파일:
// - ContentView.swift (화면에서 이 클래스 사용)


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
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = kCLHeadingFilterNone // ✅ 방향 정보 민감도 설정
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading() // ✅ 방향 업데이트 시작

        // ✅ 방향성 아이콘 설정 (화살표 이미지 필요)
        mapView.locationOverlay.icon = NMFOverlayImage(name: "location_overlay_icon")
        mapView.locationOverlay.iconWidth = CGFloat(NMF_LOCATION_OVERLAY_SIZE_AUTO)
        mapView.locationOverlay.iconHeight = CGFloat(NMF_LOCATION_OVERLAY_SIZE_AUTO)
        mapView.locationOverlay.anchor = CGPoint(x: 0.5, y: 1)
    }

    func checkIfLocationServiceIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        } else {
            print("📍 위치 서비스가 꺼져 있습니다.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        userLocation = latestLocation.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 위치 업데이트 실패: \(error.localizedDescription)")
    }

    // ✅ 기기 방향 업데이트 → 파란 삼각형 회전
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading
        if heading >= 0 {
            mapView.locationOverlay.heading = heading
        }
    }

    func updateMapWithLocation() {
        guard let location = userLocation else {
            print("❗ 사용자 위치 없음")
            return
        }
        let latLng = NMGLatLng(lat: location.latitude, lng: location.longitude)
        let cameraUpdate = NMFCameraUpdate(scrollTo: latLng, zoomTo: 15)
        mapView.moveCamera(cameraUpdate)
        mapView.locationOverlay.location = latLng
    }

    func setMarker(lat: Double, lng: Double, name: String) {
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: lat, lng: lng)
        marker.captionText = name
        marker.mapView = mapView
    }

    func getNaverMapView() -> NMFMapView {
        return mapView
    }
}

