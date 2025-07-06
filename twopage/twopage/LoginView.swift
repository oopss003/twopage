import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var loginError = ""
    @State private var isLoggedIn = false
    @State private var currentNonce: String?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            VStack {
                // 이메일 / 패스워드
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                // 이메일 로그인 버튼
                Button(action: { login() }) {
                    Text("Login")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.vertical)

                // 커스텀 Google 버튼
                Button(action: { signInWithGoogle() }) {
                    HStack(spacing: 8) {
                        // "google_logo" 라는 이름의 이미지가 Assets에 있어야 합니다.
                        Image("google_logo")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Sign in with Google")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
                    )
                }

                // Apple 로그인 버튼
                SignInWithAppleButton(.signIn, onRequest: { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                }, onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        guard let nonce = currentNonce,
                              let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
                              let appleIDToken = appleIDCredential.identityToken,
                              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                            self.loginError = "Apple 로그인에 필요한 정보를 얻지 못했습니다."
                            print(loginError)
                            return
                        }

                        // Apple용 credential (accessToken 파라미터 없이)
                        let credential = OAuthProvider.credential(
                            withProviderID: "apple.com",
                            idToken: idTokenString,
                            rawNonce: nonce     // Apple 로그인은 accessToken 없음
                        )

                        Auth.auth().signIn(with: credential) { _, error in
                            if let error = error {
                                print("Firebase Apple 로그인 실패: \(error.localizedDescription)")
                                self.loginError = error.localizedDescription
                            } else {
                                print("✅ Firebase Apple 로그인 성공")
                                proceedToTermsView()
                            }
                        }

                    case .failure(let error):
                        print("Apple 로그인 실패: \(error.localizedDescription)")
                        self.loginError = error.localizedDescription
                    }
                })
                .frame(height: 50)
                .cornerRadius(10)
                .padding(.top)
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)

                // 에러 표시
                if !loginError.isEmpty {
                    Text(loginError)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .navigationDestination(isPresented: $isLoggedIn) {
                TermsView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }

    // MARK: - 공통 진입로
    private func proceedToTermsView() {
        DispatchQueue.main.async {
            self.isLoggedIn = true
            print("✅ isLoggedIn set → TermsView 준비")
        }
    }

    // MARK: - 로그인 메서드들
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                loginError = error.localizedDescription
            } else {
                proceedToTermsView()
            }
        }
    }

    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.loginError = "Firebase 클라이언트 ID가 없습니다."
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            self.loginError = "화면의 최상단 뷰를 찾을 수 없습니다."
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error = error {
                print("Google 로그인 실패: \(error.localizedDescription)")
                self.loginError = error.localizedDescription
                return
            }
            guard let idToken = result?.user.idToken?.tokenString,
                  let accessToken = result?.user.accessToken.tokenString else {
                self.loginError = "Google 토큰 정보를 가져올 수 없습니다."
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: accessToken)
            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    print("Firebase Google 로그인 실패: \(error.localizedDescription)")
                    self.loginError = error.localizedDescription
                } else {
                    proceedToTermsView()
                }
            }
        }
    }

    // MARK: - 헬퍼 메서드
    func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    LoginView()
}


