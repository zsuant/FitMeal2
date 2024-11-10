import SwiftUI
import UIKit

// Custom UIKit-based TextField with delegate support
struct CustomTextField: UIViewRepresentable {
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField
        
        init(parent: CustomTextField) {
            self.parent = parent
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
            
            if newText.isEmpty {
                parent.weight = 0.0
                return true
            }
            
            if let _ = Double(newText), newText.filter({ $0 == "." }).count <= 1 {
                parent.weight = Double(newText) ?? 0.0
                return true
            }
            return false
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
    
    @Binding var weight: Double

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .decimalPad
        textField.placeholder = "무게를 입력하세요 (g)"
        
        textField.borderStyle = .none
        textField.layer.cornerRadius = 8
        textField.layer.masksToBounds = true
        textField.backgroundColor = UIColor.secondarySystemBackground
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 16)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 40),
            textField.widthAnchor.constraint(equalToConstant: 200)
        ])
        
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if weight > 0 {
            if weight.truncatingRemainder(dividingBy: 1) == 0 {
                uiView.text = String(format: "%.0f", weight)
            } else {
                uiView.text = "\(weight)"
            }
        } else {
            uiView.text = ""
        }
    }
}

struct WeightInputView: View {
    let item: FoodItem
    var onAddToMeal: (String, [String: Double]) -> Void
    @State private var weight: Double = 0.0
    @State private var calculatedNutrients: [String: Double] = [:]
    @State private var showAlert = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text(item.foodName)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)

            CustomTextField(weight: $weight)
                .padding(.horizontal)
                .padding(.top, 20)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .frame(width: 200, height: 40)

            Button(action: calculateNutrients) {
                Text("영양 성분 계산")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            if !calculatedNutrients.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("영양 성분 결과 (입력 무게 기준)")
                        .font(.headline)
                        .padding(.top)

                    ForEach(calculatedNutrients.keys.sorted(), id: \.self) { key in
                        Text("\(key): \(calculatedNutrients[key]!, specifier: "%.2f")")
                    }

                    Button(action: addToMeal) {
                        Text("식단에 추가")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .transition(.opacity)
            }

            Spacer()
        }
        .padding()
        .onTapGesture {
            hideKeyboard()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("추가되었습니다"), message: Text("식단에 추가되었습니다."), dismissButton: .default(Text("확인")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func calculateNutrients() {
        guard weight > 0 else { return }
        
        calculatedNutrients["칼로리"] = item.calories * weight / 100
        calculatedNutrients["탄수화물"] = item.carbs * weight / 100
        calculatedNutrients["단백질"] = item.protein * weight / 100
        calculatedNutrients["지방"] = item.fat * weight / 100
        calculatedNutrients["포화지방"] = item.saturatedFat * weight / 100
        calculatedNutrients["나트륨"] = item.sodium * weight / 100
        calculatedNutrients["당"] = item.sugar * weight / 100

        hideKeyboard()
    }

    private func addToMeal() {
        onAddToMeal(item.foodName, calculatedNutrients)
        showAlert = true
    }
}
// Utility function to dismiss the keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
