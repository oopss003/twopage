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
    private(set) var mapView = NMFMapView()  // ✅ 이 부분이 누락되어 있었음
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }

    // 위치 서비스 켜져 있는지 확인하고 권한 요청
    func checkIfLocationServiceIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        } else {
            print("📍 위치 서비스가 꺼져 있습니다.")
        }
    }

    // 위치가 변경되었을 때 호출됨
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        userLocation = latestLocation.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 위치 업데이트 실패: \(error.localizedDescription)")
    }

    // 현재 위치로 지도 이동
    func updateMapWithLocation() {
        guard let location = userLocation else {
            print("❗ 사용자 위치 없음")
            return
        }
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: location.latitude, lng: location.longitude), zoomTo: 15)
        mapView.moveCamera(cameraUpdate)
    }

    // 마커 설정
    func setMarker(lat: Double, lng: Double, name: String) {
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: lat, lng: lng)
        marker.captionText = name
        marker.mapView = mapView
    }

    // 외부에서 mapView 접근을 허용
    func getNaverMapView() -> NMFMapView {
        return mapView
    }
}

