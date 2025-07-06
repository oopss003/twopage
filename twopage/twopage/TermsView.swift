import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TermsView: View {
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

    var userEmail: String {
        Auth.auth().currentUser?.email ?? ""
    }

    let genderOptions = ["남성", "여성"]
    let styleOptions = [
        "ISTJ", "ISFJ", "INFJ", "INTJ",
        "ISTP", "ISFP", "INFP", "INTP",
        "ESTP", "ESFP", "ENFP", "ENTP",
        "ESTJ", "ESFJ", "ENFJ", "ENTJ"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("약관 동의")
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)

                Toggle("전체 동의", isOn: $isAllAgree)
                    .onChange(of: isAllAgree) { oldValue, newValue in
                        isServiceAgreement = newValue
                        isPrivacyAgreement = newValue
                        isLocationAgreement = newValue
                        isOver14 = newValue
                    }

                // 서비스 이용약관
                Group {
                    Button(action: {
                        if let url = URL(string: "https://yourdomain.com/service") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("서비스 이용약관 (필수)")
                                .foregroundColor(.primary)
                            Spacer()
                            Toggle("", isOn: $isServiceAgreement)
                                .labelsHidden()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onChange(of: isServiceAgreement) { updateAllAgree() }

                // 개인정보 수집 및 이용 동의
                Group {
                    Button(action: {
                        if let url = URL(string: "https://yourdomain.com/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("개인정보 수집 및 이용 동의 (필수)")
                                .foregroundColor(.primary)
                            Spacer()
                            Toggle("", isOn: $isPrivacyAgreement)
                                .labelsHidden()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onChange(of: isPrivacyAgreement) { updateAllAgree() }

                // 위치기반 서비스 이용약관
                Group {
                    Button(action: {
                        if let url = URL(string: "https://yourdomain.com/location") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("위치기반 서비스 이용약관 (필수)")
                                .foregroundColor(.primary)
                            Spacer()
                            Toggle("", isOn: $isLocationAgreement)
                                .labelsHidden()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onChange(of: isLocationAgreement) { updateAllAgree() }

                Toggle("만 14세 이상입니다 (필수)", isOn: $isOver14)
                    .onChange(of: isOver14) { updateAllAgree() }

                Text("성별을 선택해주세요:")
                LazyHStack(spacing: 12) {
                    Spacer()
                    ForEach(genderOptions, id: \.self) { gender in
                        Button(action: {
                            selectedGender = gender
                        }) {
                            Text(gender)
                                .frame(width: 166, height: 50)
                                .background(selectedGender == gender ? Color.blue : Color.gray.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    Spacer()
                }

                Text("스타일을 선택해주세요:")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(styleOptions, id: \.self) { style in
                        Button(action: {
                            selectedStyle = style
                        }) {
                            if UIImage(named: style) != nil {
                                Image(style)
                                    .resizable()
                                    .frame(width: 166, height: 50)
                            } else {
                                Text(style)
                                    .frame(width: 166, height: 50)
                            }
                        }
                        .background(selectedStyle == style ? Color.blue : Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }

                Button(action: submit) {
                    Text("동의 완료")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isSubmitting)
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("알림"), message: Text(alertMessage), dismissButton: .default(Text("확인")))
            }
        }
    }

    func updateAllAgree() {
        isAllAgree = isServiceAgreement && isPrivacyAgreement && isLocationAgreement && isOver14
    }

    func submit() {
        guard !userEmail.isEmpty else {
            alertMessage = "이메일 정보를 찾을 수 없습니다."
            showAlert = true
            return
        }

        guard isServiceAgreement && isPrivacyAgreement && isLocationAgreement && isOver14 else {
            alertMessage = "모든 필수 약관에 동의해주세요."
            showAlert = true
            return
        }

        guard let style = selectedStyle, let gender = selectedGender else {
            alertMessage = "성별과 스타일을 선택해주세요."
            showAlert = true
            return
        }

        isSubmitting = true
        let db = Firestore.firestore()

        db.collection("users").document(userEmail.lowercased()).setData([
            "agreedToTerms": true,
            "selectedStyle": style,
            "selectedGender": gender,
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

struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView()
    }
}

