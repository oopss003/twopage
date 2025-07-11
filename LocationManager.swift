//
//  LocationManager.swift
//  twopage
//  최종전
//  Created by jae on 7/8/25.
// 파일명: LocationManager.swift
// 기능: 이 파일은 `CLLocationManager`를 사용하여 위치 서비스를 관리합니다.
// 위치 권한을 요청하고, 위치 업데이트를 받아 사용자의 위치를 제공합니다.
// 관련 파일: Coordinator.swift (이 파일에서 제공하는 위치 정보를 사용하여 지도 업데이트)

import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager() // CLLocationManager 객체 생성
    @Published var userLocation: CLLocationCoordinate2D? // 위치를 저장할 프로퍼티
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // 권한 요청
        locationManager.startUpdatingLocation() // 위치 업데이트 시작
    }
    
    // 위치 업데이트가 성공적으로 이루어졌을 때 호출되는 메서드
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate // 위치 정보 저장
    }
    
    // 위치 업데이트에 실패했을 때 호출되는 메서드
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 업데이트 실패: \(error.localizedDescription)")
    }
}
