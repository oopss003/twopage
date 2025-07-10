//
//  NaverMap.swift
//  twopage
//
//  Created by jae on 7/8/25.
//

//
//  NaverMap.swift
//  NaverMap
//
//  Created by 황성진 on 12/28/23.
//
// 파일명: NaverMap.swift
// 기능: SwiftUI에서 네이버 지도를 표시하는 UIViewRepresentable 래퍼

import SwiftUI
import NMapsMap

struct NaverMap: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator.shared
    }

    func makeUIView(context: Context) -> NMFMapView {
        context.coordinator.getNaverMapView()
    }

    func updateUIView(_ uiView: NMFMapView, context: Context) {
        // 필요 시 지도 갱신 작업
    }
}
