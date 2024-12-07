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
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Image Section
                    profileImageSection
                    
                    // Nickname Section
                    editableFieldSection(title: "닉네임", value: $nickname, isEditing: $isEditingNickname)
                    
                    // Height, Weight, Age Sections
                    editableFieldSection(title: "키 (cm)", value: $height, isEditing: $isEditingHeight)
                    editableFieldSection(title: "몸무게 (kg)", value: $weight, isEditing: $isEditingWeight)
                    editableFieldSection(title: "나이", value: $age, isEditing: $isEditingAge)
                    
                    // Recommended Calorie Calculation
                    if let recommendedCalories = calculateCalories() {
                        Text("권장 칼로리: \(recommendedCalories) kcal")
                            .font(.headline)
                            .padding(.top, 10)
                    }
                    
                    // Change Password Button
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
                .padding()
            }
            .navigationTitle("내 페이지")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileImage)
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    private var profileImageSection: some View {
        VStack {
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                    .shadow(radius: 10)
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
                            .frame(width: 120, height: 120)
                        Image(systemName: "camera")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                    }
                    .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                    .shadow(radius: 10)
                }
            }
        }
    }

    private func editableFieldSection(title: String, value: Binding<String>, isEditing: Binding<Bool>) -> some View {
        VStack {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                if isEditing.wrappedValue {
                    TextField(title, text: value, onCommit: {
                        isEditing.wrappedValue = false
                        updateUserProfile()
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)
                    .frame(width: 200)
                } else {
                    Text(value.wrappedValue.isEmpty ? "입력 안함" : value.wrappedValue)
                        .foregroundColor(value.wrappedValue.isEmpty ? .gray : .primary)
                        .font(.body)
                        .frame(width: 200)
                    Button(action: {
                        isEditing.wrappedValue = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                            .padding(.leading, 8)
                    }
                }
            }
            Divider()
        }
        .padding(.horizontal)
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
        
        // Profile Image upload
        if let profileImage = profileImage {
            uploadImageToStorage(profileImage) { imageURL in
                if let imageURL = imageURL {
                    userData["profileImageURL"] = imageURL
                }
                db.collection("users").document(userID).setData(userData, merge: true) { error in
                    if let error = error {
                        print("Error updating user profile: \(error.localizedDescription)")
                    } else {
                        print("User profile successfully updated!")
                    }
                }
            }
        } else {
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
        
        let bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        return Int(bmr * 1.55) // Moderate activity factor
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

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
struct ChangePasswordView: View {
    @State private var password: String = ""
    @State private var showAlert = false // State to control alert visibility
    
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("비밀번호 변경"), message: Text("비밀번호가 변경되었습니다."), dismissButton: .default(Text("확인")))
        }
    }
    
    private func changePassword() {
        let user = Auth.auth().currentUser
        user?.updatePassword(to: password) { error in
            if let error = error {
                print("Error updating password: \(error.localizedDescription)")
            } else {
                print("Password successfully updated!")
                showAlert = true // Show the alert upon success
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
