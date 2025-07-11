// 파일명: ContentView.swift
// 기능:
// - NaverMap 지도 위에 Firestore에서 불러온 장소 마커를 표시
// - 사용자 현재 위치를 표시하고, LocationButton을 눌러 지도를 현재 위치로 이동시킴
// 관련 파일:
// - Coordinator.swift (지도 및 마커 제어)
// - FireStoreManager.swift (Firestore에서 위치 데이터 로딩)
import SwiftUI
import CoreLocationUI
import NMapsMap

struct ContentView: View {
    @StateObject var coordinator      = Coordinator.shared
    @StateObject var firestoreManager = FireStoreManager()
    
    var body: some View {
        ZStack {
            NaverMap()
                .ignoresSafeArea()
                .onAppear { coordinator.checkIfLocationServiceIsEnabled() }
            
            // ── 현재 위치 버튼 ──
            VStack {
                HStack {
                    LocationButton(.currentLocation) {
                        coordinator.updateMapWithLocation()
                    }
                    .frame(width: 70, height: 70)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(35)
                    .labelStyle(.iconOnly)
                    .symbolVariant(.fill)
                    .padding(.leading, 16)
                    .padding(.top, 30)
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            Task {
                await firestoreManager.fetchStores()          // 🔹 매장 로드
                for store in firestoreManager.stores {        // 🔹 마커 생성
                    coordinator.setMarker(
                        lat:  store.lat,
                        lng:  store.lng,
                        name: store.name
                    )
                }
            }
        }
    }
}


#Preview {
    ContentView()
}

