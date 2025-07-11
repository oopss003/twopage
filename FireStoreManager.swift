// FireStoreManager.swift
// 기존 기능 유지 + 마커용 텍스트 이미지 생성 함수 + 그림자 추가 (6자 이상 "…" 처리)

import Foundation
import FirebaseFirestore
import UIKit

// MARK: - Store 모델 (Firestore <-> Swift)
struct Store: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String          // 매장명
    var lat:  Double          // 위도
    var lng:  Double          // 경도

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case lat
        case lng
    }
}

// MARK: - FireStoreManager
class FireStoreManager: ObservableObject {
    @Published var stores: [Store] = []          // 지도에 뿌릴 매장 리스트
    private let db = Firestore.firestore()

    /// `stores` 컬렉션 로드 (비동기)
    @MainActor
    func fetchStores() async {
        do {
            let snap = try await db.collection("stores").getDocuments()
            var temp: [Store] = []
            for doc in snap.documents {
                let d = doc.data()
                guard
                    let name = d["name"] as? String,
                    let lat  = d["lat"]  as? Double,
                    let lng  = d["lng"]  as? Double
                else { continue }
                let store = Store(id: doc.documentID, name: name, lat: lat, lng: lng)
                temp.append(store)
            }
            stores = temp
            print("✅ Firestore: \(stores.count)개 매장 로드 완료")
        } catch {
            print("❌ Firestore fetch 실패:", error)
        }
    }

    // MARK: - 마커용 텍스트 이미지 (동적 생성)
    /// - Parameter storeName: 매장 이름
    /// - Returns: 말풍선 모양의 UIImage (최대 6자, 초과 시 "…", 그림자 포함)
    func makeTextMarkerImage(storeName: String) -> UIImage? {
        let maxLength = 6
        let displayName = storeName.count > maxLength ? String(storeName.prefix(maxLength)) + "…" : storeName

        // 배경 말풍선 이미지 (Assets 이름: "macker")
        guard let baseImage = UIImage(named: "macker") else { return nil }
        let size = baseImage.size

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        baseImage.draw(in: CGRect(origin: .zero, size: size))

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let fontSize = min(28, size.height * 0.5)

        // ✅ 텍스트 속성 (그림자 포함)
        let shadow = NSShadow()
        shadow.shadowColor = UIColor(white: 0, alpha: 0.6)
        shadow.shadowOffset = CGSize(width: 1, height: 1)
        shadow.shadowBlurRadius = 2

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraph,
            .shadow: shadow // ← 그림자 적용
        ]

        let textHeight = displayName.size(withAttributes: attrs).height
        let textRect = CGRect(x: 0, y: (size.height - textHeight) / 2, width: size.width, height: textHeight)
        displayName.draw(in: textRect, withAttributes: attrs)

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
