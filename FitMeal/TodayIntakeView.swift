import SwiftUI

struct TodayIntakeView: View {
    @State private var meals: [String: [String: [(String, [String: Double])]]] = [:]
    @State private var selectedDate: Date = Date()
    @State private var selectedMealType: String = "아침"
    @State private var showingDatePicker = false

    var body: some View {
        VStack {
            Button(action: { showingDatePicker.toggle() }) {
                Text("날짜 선택: \(formatDate(date: selectedDate))")
                    .font(.headline)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .padding()
            .popover(isPresented: $showingDatePicker) {
                VStack {
                    // Compact calendar date picker
                    DatePicker(
                        "날짜 선택",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle()) // Use graphical style for a calendar look
                    .frame(width: 280, height: 300) // Adjust size for compactness
                    .padding()

                    Button("선택", action: {
                        showingDatePicker = false // Close the date picker after selection
                    })
                    .padding()
                }
                .frame(width: 300, height: 350) // Small popover size
                .cornerRadius(12)
                .shadow(radius: 10)
            }

            Picker("식사 유형 선택", selection: $selectedMealType) {
                Text("아침").tag("아침")
                Text("점심").tag("점심")
                Text("저녁").tag("저녁")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            List {
                ForEach(mealsForSelectedDate()[selectedMealType] ?? [], id: \.0) { foodName, nutrients in
                    Text("\(foodName): \(nutrients["칼로리"]!, specifier: "%.2f") kcal")
                }
            }

            Spacer()
        }
        .navigationTitle("오늘의 식단")
    }

    private func mealsForSelectedDate() -> [String: [(String, [String: Double])]] {
        let dateKey = formatDate(date: selectedDate)
        return meals[dateKey] ?? [:]
    }

    private func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
