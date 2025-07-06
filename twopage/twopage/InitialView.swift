import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn

struct InitialView: View {
    // 현재 로그인 상태
    @State private var userLoggedIn = (Auth.auth().currentUser != nil)
    // 리스너 핸들을 보관할 변수
    @State private var authHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        VStack {
            if userLoggedIn {
                ContentView()
            } else {
                LoginView()
            }
        }
        // 뷰가 나타날 때 리스너 등록
        .onAppear {
            authHandle = Auth.auth()
                .addStateDidChangeListener { _, user in
                    userLoggedIn = (user != nil)
                }
        }
        // 뷰가 사라질 때 리스너 해제
        .onDisappear {
            if let handle = authHandle {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
}
