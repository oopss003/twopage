//
//  AppDelegate.swift
//  twopage
//
//  Created by jae on 7/8/25.
//

import SwiftUI
import FirebaseCore
import NMapsMap

// AppDelegate 클래스 정의
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()
        
        // 네이버 지도 API 키 설정
        NMFAuthManager.shared().ncpKeyId = "qpbrmxiff4"
        
        return true
    }
}






