import SwiftUI
import Firebase
import FirebaseAuth
import LocalAuthentication

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Text("Fit Meal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 30)

            TextField("이메일", text: $email)
                .padding()
                .background(Color(UIColor.systemGray5))
                .cornerRadius(10)
                .shadow(radius: 2)
                .foregroundColor(.primary)
                .padding(.bottom, 10)

            SecureField("비밀번호", text: $password)
                .padding()
                .background(Color(UIColor.systemGray5))
                .cornerRadius(10)
                .shadow(radius: 2)
                .foregroundColor(.primary)
                .padding(.bottom, 10)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }

            Button(action: {
                loginUser()
            }) {
                Text("로그인")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding(.top, 20)

            Button(action: {
                authenticateWithFaceID()
            }) {
                Text("Face ID로 로그인")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding(.top, 10)

            NavigationLink(destination: SignUpView(isLoggedIn: $isLoggedIn), label: {
                Text("회원가입")
                    .foregroundColor(Color.blue)
                    .fontWeight(.semibold)
            })
            .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding()
    }

    private func loginUser() {
        // Firebase 로그인 로직 구현
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.isLoggedIn = true
            }
        }
    }

    private func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Face ID로 로그인하세요."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isLoggedIn = true
                    } else {
                        self.errorMessage = "Face ID 인증에 실패했습니다."
                    }
                }
            }
        } else {
            self.errorMessage = "이 기기에서 Face ID를 사용할 수 없습니다."
        }
    }
}
