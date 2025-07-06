import SwiftUI
import WebKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

// 🔹 JavaScript → Swift 메시지 브리지
class WebBridge: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let body = message.body as? String,
              let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["type"] as? String == "storeClick" else {
            print("❌ 메시지 파싱 실패")
            return
        }

        let storeName = json["storeName"] as? String ?? "unknown"
        let storeId = json["storeId"] as? String ?? "none"
        let email = Auth.auth().currentUser?.email ?? "guest@example.com"
        let time = Date()

        // ✅ Firestore 저장
        let db = Firestore.firestore()
        db.collection("clickLogs").addDocument(data: [
            "storeId": storeId,
            "storeName": storeName,
            "userEmail": email,
            "clickedAt": Timestamp(date: time)
        ]) { err in
            if let err = err {
                print("❌ 저장 실패:", err.localizedDescription)
            } else {
                print("✅ 클릭 로그 저장 완료:", storeName)
            }
        }
    }
}

// 🔹 WebView 구성
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(WebBridge(), name: "bridge")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.backgroundColor = .white
        webView.backgroundColor = .white

        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// 🔹 MapView (ZStack + SafeAreaInset 사용)
struct MapView: View {
    var body: some View {
        VStack {
            Spacer().frame(height: 10) // 상단 노치 대응 여백 추가

            WebView(url: URL(string: "https://inwave.ai.kr/view_stores_app.html")!)
                .ignoresSafeArea() // 전체 꽉 채우기

            Spacer().frame(height: 10) // 하단 홈 인디케이터 대응 여백 추가
        }
        .safeAreaInset(edge: .top) {
            Spacer().frame(height: 10) // 상단 노치 대응
        }
        .safeAreaInset(edge: .bottom) {
            Spacer().frame(height: 10) // 하단 홈 인디케이터 대응
        }
    }
}

#Preview {
    MapView()
}
