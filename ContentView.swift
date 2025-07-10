// 파일명: ContentView.swift
// 기능:
// - NaverMap 지도 위에 Firestore에서 불러온 장소 마커를 표시
// - 사용자 현재 위치를 표시하고, LocationButton을 눌러 지도를 현재 위치로 이동시킴
// 관련 파일:
// - Coordinator.swift (지도 및 마커 제어)
// - FireStoreManager.swift (Firestore에서 위치 데이터 로딩)

import SwiftUI
import CoreLocationUI // LocationButton 사용
import NMapsMap        // 네이버 지도

struct ContentView: View {
    @StateObject var coordinator = Coordinator.shared
    @StateObject var firestoreManager = FireStoreManager()
    
    var body: some View {
        ZStack {
            VStack {
                NaverMap()
                    .ignoresSafeArea(.all, edges: .top)
                    .onAppear {
                        coordinator.checkIfLocationServiceIsEnabled()
                    }
                
                Spacer()
                
                // 현재 위치로 이동하는 버튼
                LocationButton(.currentLocation) {
                    coordinator.updateMapWithLocation()
                }
                .frame(width: 60, height: 60)
                .cornerRadius(30)
                .labelStyle(.iconOnly)
                .symbolVariant(.fill)
                .foregroundColor(.white)
                .padding()
            }
        }
        .onAppear {
            Task {
                await firestoreManager.fetchData()
                for item in firestoreManager.myDataModels {
                    coordinator.setMarker(
                        lat: item.location.latitude,
                        lng: item.location.longitude,
                        name: item.name
                    )
                }
            }
        }
    }
}


//
//#Preview {
//    ContentView()
//}
