// 파일명: Coordinator.swift
// 기능:
// - 위치 서비스 활성화 및 권한 요청
// - 네이버 지도에 마커 표시
// - 현재 위치를 지도 중심으로 이동
// - 위치 오버레이(파란 원 + 빔) 적용
// - 헤딩 값으로 지도까지 회전 (카메라 bearing 직접 갱신)

// Coordinator.swift
// 기존 기능 그대로 유지 + 마커 아이콘을 “macker” 배경 위에 매장명(6자 초과 … 처리)으로 교체

import Foundation
import CoreLocation
import NMapsMap
import UIKit                         // ← UIImage 사용을 위해 추가

class Coordinator: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = Coordinator()
    
    private let locationManager = CLLocationManager()
    private(set) var mapView = NMFMapView()
    @Published var userLocation: CLLocationCoordinate2D?
    
    // ───────── 초기화 ─────────
    override init() {
        super.init()
        
        // 위치 매니저
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter  = kCLHeadingFilterNone
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        // 내 위치 “핀”
        let overlay = mapView.locationOverlay
        overlay.icon        = NMFOverlayImage(name: "loc_blue_dot")
        overlay.iconWidth   = 120
        overlay.iconHeight  = 120
        overlay.anchor      = CGPoint(x: 0.5, y: 0.5)
        
        overlay.subIcon       = NMFOverlayImage(name: "loc_beam")
        overlay.subIconWidth  = 30
        overlay.subIconHeight = 30
        overlay.subAnchor     = CGPoint(x: 0.5, y: 0.65)
        overlay.circleRadius  = 0
        
        mapView.positionMode = .compass
        
        let initialLocation = NMGLatLng(lat: 37.4890303, lng: 126.8101745)
        let cameraUpdate = NMFCameraUpdate(scrollTo: initialLocation, zoomTo: 15)
        mapView.moveCamera(cameraUpdate)// 지도도 회전
    }
    
    // ───────── 권한 체크 ─────────
    func checkIfLocationServiceIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        } else {
            print("📍 위치 서비스가 꺼져 있습니다.")
        }
    }
    
    // ───────── CLLocationManagerDelegate ─────────
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        userLocation = latest.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading
        guard heading >= 0 else { return }
        
        // 지도 회전
        let params = NMFCameraUpdateParams()
        params.rotate(to: heading)
        mapView.moveCamera(NMFCameraUpdate(params: params))
        mapView.locationOverlay.heading = heading     // 핀 화살표 고정
        
        print("▶︎ Heading & camera bearing: \(heading)°")
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("❌ 위치 업데이트 실패:", error.localizedDescription)
    }
    
    // ───────── 지도 제어 ─────────
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
    
    // ───────── 마커 생성 (말풍선 이미지 사용) ─────────
    func setMarker(lat: Double, lng: Double, name: String) {
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: lat, lng: lng)
        marker.anchor   = CGPoint(x: 0.5, y: 1)          // 말풍선 하단이 좌표에 닿도록
        
        // FireStoreManager의 함수로 말풍선 이미지 생성
        if let img = FireStoreManager().makeTextMarkerImage(storeName: name) {
            marker.iconImage = NMFOverlayImage(image: img)
            marker.width  = CGFloat(NMF_MARKER_SIZE_AUTO)
            marker.height = CGFloat(NMF_MARKER_SIZE_AUTO)
        }
        
        marker.mapView = mapView
    }
    
    // NMFMapView 제공
    func getNaverMapView() -> NMFMapView {
        return mapView
    }
}

