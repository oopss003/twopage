import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SafariServices

// 1️⃣ SFSafariViewController 래퍼
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct TermsView: View {
    // MARK: — State
    @State private var isServiceAgreement = false
    @State private var isPrivacyAgreement = false
    @State private var isLocationAgreement = false
    @State private var isOver14 = false
    @State private var isAllAgree = false
    @State private var selectedStyle: String? = nil
    @State private var selectedGender: String? = nil
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // 웹뷰 시트용
    @State private var showSafari = false
    @State private var safariURL: URL?

    // MARK: — Data
    private var userEmail: String {
        Auth.auth().currentUser?.email ?? ""
    }
    private let genderOptions = ["남성", "여성"]
    private let styleOptions = [
        "ISTJ","ISFJ","INFJ","INTJ",
        "ISTP","ISFP","INFP","INTP",
        "ESTP","ESFP","ENFP","ENTP",
        "ESTJ","ESFJ","ENFJ","ENTJ"
    ]
    
    // MARK: — Layout
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("약관 동의")
                    .font(.title).bold()
                    .frame(maxWidth: .infinity, alignment: .center)

                // 전체 동의
                Toggle("전체 동의", isOn: $isAllAgree)
                    .onChange(of: isAllAgree) { _, new in
                        isServiceAgreement = new
                        isPrivacyAgreement = new
                        isLocationAgreement = new
                        isOver14 = new
                    }

                // 개별 약관
                ForEach([
                    ("서비스 이용약관 (필수)", $isServiceAgreement, "https://yourdomain.com/service"),
                    ("개인정보 수집 및 이용 (필수)", $isPrivacyAgreement, "https://inwave.ai.kr/privacy_policy.html"),
                    ("위치기반 서비스 이용약관 (필수)", $isLocationAgreement, "https://yourdomain.com/location")
                ], id: \.0) { label, binding, urlString in
                    HStack {
                        // 웹뷰 모달로 열기
                        Button {
                            guard let url = URL(string: urlString) else { return }
                            safariURL = url
                            showSafari = true
                        } label: {
                            Text(label)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Toggle("", isOn: binding)
                            .labelsHidden()
                    }
                    .onChange(of: binding.wrappedValue) { _ in
                        updateAllAgree()
                    }
                }

                // 나이 확인
                Toggle("만 14세 이상입니다 (필수)", isOn: $isOver14)
                    .onChange(of: isOver14) { _ in
                        updateAllAgree()
                    }

                // 성별 선택
                Text("성별을 선택해주세요:")
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(genderOptions, id: \.self) { gender in
                        Button { selectedGender = gender }
                        label: {
                            Text(gender)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(selectedGender == gender
                                            ? Color.blue
                                            : Color.gray.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }

                // 스타일 선택
                Text("스타일을 선택해주세요:")
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(styleOptions, id: \.self) { style in
                        Button { selectedStyle = style }
                        label: {
                            Group {
                                if let uiImage = UIImage(named: style) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                } else {
                                    Text(style)
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                }
                            }
                            .background(selectedStyle == style
                                        ? Color.blue
                                        : Color.gray.opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }

                // 동의 완료 버튼
                Button("동의 완료") { submit() }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(isSubmitting)

                // 알림 메시지
                if showAlert {
                    Text(alertMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        // 1️⃣ 시트로 웹뷰 띄우기
        .sheet(isPresented: $showSafari) {
            if let url = safariURL {
                SafariView(url: url)
            }
        }
    }
    
    // MARK: — Helpers
    private func updateAllAgree() {
        isAllAgree = isServiceAgreement
            && isPrivacyAgreement
            && isLocationAgreement
            && isOver14
    }
    
    private func submit() {
        guard !userEmail.isEmpty else {
            alertMessage = "이메일 정보가 없습니다."
            showAlert = true
            return
        }
        guard isAllAgree else {
            alertMessage = "모든 필수 약관에 동의해주세요."
            showAlert = true
            return
        }
        guard let gender = selectedGender,
              let style = selectedStyle else {
            alertMessage = "성별과 스타일을 선택해주세요."
            showAlert = true
            return
        }
        
        isSubmitting = true
        let db = Firestore.firestore()
        db.collection("users")
          .document(userEmail.lowercased())
          .setData([
            "agreedToTerms": true,
            "selectedGender": gender,
            "selectedStyle": style,
            "serviceAgreement": isServiceAgreement,
            "privacyAgreement": isPrivacyAgreement,
            "locationAgreement": isLocationAgreement,
            "over14": isOver14
          ]) { error in
            isSubmitting = false
            if let error = error {
                alertMessage = "저장 실패: \(error.localizedDescription)"
            } else {
                alertMessage = "정상적으로 저장되었습니다."
            }
            showAlert = true
        }
    }
}

#Preview {
    TermsView()
}



