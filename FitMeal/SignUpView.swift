import SwiftUI
import Firebase
import FirebaseAuth

struct SignUpView: View {
    @Binding var isLoggedIn: Bool // 바인딩 변수

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Text("회원가입")
                .font(.largeTitle)
                .padding()

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
                registerUser()
            }) {
                Text("회원가입")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding()
    }

    private func registerUser() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            self.isLoggedIn = true 
        }
    }
}
