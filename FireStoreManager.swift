import Foundation
import FirebaseFirestore

/// Firestore `stores` 컬렉션에서 사용하는 최소 모델
struct StoreModel {
    let name: String
    let lat : Double
    let lng : Double
}

class FireStoreManager: ObservableObject {
    @Published var stores: [StoreModel] = []
    
    /// `stores` 컬렉션 전체 로드
    @MainActor
    func fetchStores() async {
        let db = Firestore.firestore()
        do {
            let snap = try await db.collection("stores").getDocuments()
            var temp: [StoreModel] = []
            for doc in snap.documents {
                let d = doc.data()
                guard
                    let name = d["name"] as? String,
                    let lat  = d["lat"]  as? Double,
                    let lng  = d["lng"]  as? Double
                else { continue }                       // 필수 필드 없으면 건너뜀
                temp.append(StoreModel(name: name, lat: lat, lng: lng))
            }
            stores = temp
            print("✅ Firestore: \(stores.count)개 매장 로드 완료")
        } catch {
            print("❌ Firestore fetch 실패:", error)
        }
    }
}

