import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct MyPageView: View {
    @State private var nickname: String = "기본 닉네임"
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var age: String = ""
    @State private var profileImage: Image? = nil
    @State private var showingImagePicker = false
    @State private var isEditingNickname = false
    @State private var isEditingHeight = false
    @State private var isEditingWeight = false
    @State private var isEditingAge = false

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    if let profileImage = profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .onTapGesture {
                                showingImagePicker = true
                            }
                    } else {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                Image(systemName: "camera")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // 닉네임 입력
                    HStack {
                        if isEditingNickname {
                            TextField("닉네임 입력", text: $nickname, onCommit: {
                                updateUserProfile()
                                isEditingNickname = false
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.largeTitle)
                            .padding()
                        } else {
                            Text(nickname)
                                .font(.largeTitle)
                                .padding(.top, 8)
                            Button(action: {
                                isEditingNickname = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    // 키, 몸무게, 나이 입력 필드
                    VStack(spacing: 16) {
                        InputField(title: "키 (cm)", value: $height, isEditing: $isEditingHeight)
                        InputField(title: "몸무게 (kg)", value: $weight, isEditing: $isEditingWeight)
                        InputField(title: "나이", value: $age, isEditing: $isEditingAge)
                    }
                    .padding()

                    // 권장 칼로리 및 영양 성분 표시
                    if let recommendedCalories = calculateCalories() {
                        Text("권장 칼로리: \(recommendedCalories) kcal")
                            .font(.headline)
                            .padding()
                    }
                }
                .padding()

                NavigationLink(destination: ChangePasswordView()) {
                    Text("비밀번호 변경")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("내 페이지") // 네비게이션 타이틀 추가
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileImage)
            }
        }
    }

    private func updateUserProfile() {
        guard let user = Auth.auth().currentUser else { return }
        let userID = user.uid
        let db = Firestore.firestore()
        var userData: [String: Any] = [
            "nickname": nickname,
            "height": height,
            "weight": weight,
            "age": age
        ]

        // 프로필 이미지가 선택된 경우에만 업로드
        if let profileImage = profileImage {
            uploadImageToStorage(profileImage) { imageURL in
                if let imageURL = imageURL {
                    userData["profileImageURL"] = imageURL
                }
                // Firestore 업데이트
                db.collection("users").document(userID).setData(userData, merge: true) { error in
                    if let error = error {
                        print("Error updating user profile: \(error.localizedDescription)")
                    } else {
                        print("User profile successfully updated!")
                    }
                }
            }
        } else {
            // 프로필 이미지가 없을 때 닉네임만 업데이트
            db.collection("users").document(userID).setData(userData, merge: true) { error in
                if let error = error {
                    print("Error updating user profile: \(error.localizedDescription)")
                } else {
                    print("User profile successfully updated!")
                }
            }
        }
    }

    private func calculateCalories() -> Int? {
        guard let height = Double(height),
              let weight = Double(weight),
              let age = Int(age) else { return nil }

        // 간단한 BMR 계산 (Mifflin-St Jeor 식)
        let bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5 // 남성 기준
        return Int(bmr * 1.55) // 활동 계수 1.55 (중간 활동)
    }

    private func uploadImageToStorage(_ image: Image, completion: @escaping (String?) -> Void) {
        guard let uiImage = image.asUIImage() else { completion(nil); return }
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("profile_images/\(UUID().uuidString).jpg")

        guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else { completion(nil); return }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        imageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            imageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(url?.absoluteString)
            }
        }
    }
}

// 입력 필드 뷰
struct InputField: View {
    var title: String
    @Binding var value: String
    @Binding var isEditing: Bool

    var body: some View {
        HStack {
            if isEditing {
                TextField(title, text: $value, onCommit: {
                    isEditing = false
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            } else {
                Text(value.isEmpty ? "\(title): 입력 안함" : "\(title): \(value)")
                    .padding(.top, 8)
                Button(action: {
                    isEditing = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// 비밀번호 변경 뷰
struct ChangePasswordView: View {
    @State private var password: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("새 비밀번호")) {
                SecureField("비밀번호 입력", text: $password)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(10)
            }
            Button(action: {
                changePassword()
            }) {
                Text("비밀번호 변경")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .navigationTitle("비밀번호 변경")
    }
    
    private func changePassword() {
        let user = Auth.auth().currentUser
        user?.updatePassword(to: password) { error in
            if let error = error {
                print("Error updating password: \(error.localizedDescription)")
            } else {
                print("Password successfully updated!")
            }
        }
    }
}

// 이미지 선택기 구현
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: Image?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = Image(uiImage: uiImage)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = CGSize(width: 100, height: 100) // 원하는 크기로 조정
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
        }
    }
}
