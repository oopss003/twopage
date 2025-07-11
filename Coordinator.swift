// 파일명: Coordinator.swift
// 기능:
// - 위치 서비스 활성화 및 권한 요청
// - 네이버 지도에 마커 표시
// - 현재 위치를 지도 중심으로 이동
// - 위치 오버레이(파란 원 + 빔) 적용
// - 헤딩 값으로 지도까지 회전 (카메라 bearing 직접 갱신)

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
        locationManager.headingFilter  = kCLHeadingFilterNone
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        // 위치 오버레이 설정
        let overlay = mapView.locationOverlay
        overlay.icon        = NMFOverlayImage(name: "loc_blue_dot")
        overlay.iconWidth   = 120
        overlay.iconHeight  = 120
        overlay.anchor      = CGPoint(x: 0.5, y: 0.5)
        
        overlay.subIcon       = NMFOverlayImage(name: "loc_beam")
        overlay.subIconWidth  = 30
        overlay.subIconHeight = 30
        overlay.subAnchor     = CGPoint(x: 0.5, y: 0.65)
        
        overlay.circleRadius = 0
        
        // 위치 추적·줌 유지용 (.compass)
        mapView.positionMode = .compass
    }
    
    // MARK: - 권한 체크
    func checkIfLocationServiceIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        } else {
            print("📍 위치 서비스가 꺼져 있습니다.")
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        userLocation = latest.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading
        guard heading >= 0 else { return }
        
        // 1) 카메라 bearing을 헤딩에 맞춰 회전
        let params = NMFCameraUpdateParams()
        params.rotate(to: heading)
        mapView.moveCamera(NMFCameraUpdate(params: params))
        
        // 2) 화살표는 화면 위쪽 고정
        mapView.locationOverlay.heading = 0
        
        // 3) 디버그 로그
        print("▶︎ Heading & camera bearing: \(heading)°")
    }
    
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
        let camUpdate = NMFCameraUpdate(scrollTo: latLng, zoomTo: 18)
        mapView.moveCamera(camUpdate)
        mapView.locationOverlay.location = latLng
    }
    
    // 마커 생성
    func setMarker(lat: Double, lng: Double, name: String) {
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: lat, lng: lng)
        marker.captionText = name
        marker.mapView = mapView
    }
    
    // NMFMapView 반환
    func getNaverMapView() -> NMFMapView {
        return mapView
    }
}

