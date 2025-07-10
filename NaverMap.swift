//
//  twopageApp.swift
//  twopage
//
//  Created by jae on 7/8/25.
//

//
//  NaverMapApp.swift
//  NaverMap
//
//  Created by 황성진 on 12/28/23.
//
import SwiftUI
import FirebaseCore

@main
struct twopageApp: App {
    // Firebase 설정을 위해 AppDelegateAdaptor 사용
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
