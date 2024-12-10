import SwiftUI

struct NutrientProgress: View {
    let nutrientName: String
    let current: Double
    let recommended: Double
    let color: Color
    
    var percentage: Double {
        min((current / recommended) * 100, 100)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(nutrientName)
                Spacer()
                Text("\(Int(percentage))%")
            }
            .font(.subheadline)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 10)
                        .cornerRadius(5)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 10)
                        .cornerRadius(5)
                }
            }
            .frame(height: 10)
        }
    }
}

struct TodayIntakeView: View {
    @State private var meals: [String: [String: [(String, Int, [String: Double])]]] = [:]
    @State private var selectedDate: Date = Date()
    @State private var selectedMealType: String = "점심" // 기본 선택을 점심으로 변경
    @State private var showingDatePicker = false
    
    // 권장 섭취량 설정
    let recommendedDaily = [
        "칼로리": 2100.0,    // kcal
        "탄수화물": 324.0,   // g (총 칼로리의 55-65%)
        "단백질": 55.0,      // g (체중 kg당 1g 기준, 평균 체중 55kg 가정)
        "지방": 58.0         // g (총 칼로리의 25% 기준)
    ]

    // 초기 예시 데이터 설정
    init() {
        let today = formatDate(date: Date())
        // 점심 식사 예시 - (음식이름, 그램수, 영양성분)
        let lunch: [(String, Int, [String: Double])] = [
            ("쌀밥", 210, ["칼로리": 310.0, "탄수화물": 68.0, "단백질": 5.0, "지방": 0.5]),
            ("무국", 300, ["칼로리": 45.0, "탄수화물": 8.0, "단백질": 3.0, "지방": 1.0])
        ]
        
        // 초기 데이터 설정
        _meals = State(initialValue: [
            today: [
                "아침": [],
                "점심": lunch, // 점심으로 이동
                "저녁": []
            ]
        ])
    }

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
            .sheet(isPresented: $showingDatePicker) {
                DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
            }

            Picker("식사 유형 선택", selection: $selectedMealType) {
                Text("아침").tag("아침")
                Text("점심").tag("점심")
                Text("저녁").tag("저녁")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            List {
                ForEach(mealsForSelectedDate()[selectedMealType] ?? [], id: \.0) { foodName, amount, nutrients in
                    VStack(alignment: .leading) {
                        Text(foodName)
                            .font(.headline)
                        Text("\(amount)g • \(nutrients["칼로리"] ?? 0, specifier: "%.1f") kcal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("탄수화물: \(nutrients["탄수화물"] ?? 0, specifier: "%.1f")g")
                            Text("단백질: \(nutrients["단백질"] ?? 0, specifier: "%.1f")g")
                            Text("지방: \(nutrients["지방"] ?? 0, specifier: "%.1f")g")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            // 영양성분 총합 및 권장섭취량 대비 퍼센트 표시
            if let selectedMeals = mealsForSelectedDate()[selectedMealType] {
                VStack(alignment: .leading, spacing: 16) {
                    Text("영양성분 총합")
                        .font(.headline)
                    
                    let totalNutrients = calculateTotalNutrients(meals: selectedMeals)
                    
                    // 칼로리
                    NutrientProgress(
                        nutrientName: "칼로리 (\(Int(totalNutrients["칼로리"] ?? 0))kcal)",
                        current: totalNutrients["칼로리"] ?? 0,
                        recommended: recommendedDaily["칼로리"] ?? 0,
                        color: .orange
                    )
                    
                    // 탄수화물
                    NutrientProgress(
                        nutrientName: "탄수화물 (\(Int(totalNutrients["탄수화물"] ?? 0))g)",
                        current: totalNutrients["탄수화물"] ?? 0,
                        recommended: recommendedDaily["탄수화물"] ?? 0,
                        color: .blue
                    )
                    
                    // 단백질
                    NutrientProgress(
                        nutrientName: "단백질 (\(Int(totalNutrients["단백질"] ?? 0))g)",
                        current: totalNutrients["단백질"] ?? 0,
                        recommended: recommendedDaily["단백질"] ?? 0,
                        color: .red
                    )
                    
                    // 지방
                    NutrientProgress(
                        nutrientName: "지방 (\(Int(totalNutrients["지방"] ?? 0))g)",
                        current: totalNutrients["지방"] ?? 0,
                        recommended: recommendedDaily["지방"] ?? 0,
                        color: .green
                    )
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding()
            }

            Spacer()
        }
        .navigationTitle("오늘의 식단")
    }

    // 영양성분 총합 계산 함수
    private func calculateTotalNutrients(meals: [(String, Int, [String: Double])]) -> [String: Double] {
        var totals = ["칼로리": 0.0, "탄수화물": 0.0, "단백질": 0.0, "지방": 0.0]
        
        for (_, _, nutrients) in meals {
            for (nutrient, value) in nutrients {
                totals[nutrient, default: 0.0] += value
            }
        }
        
        return totals
    }

    private func mealsForSelectedDate() -> [String: [(String, Int, [String: Double])]] {
        let dateKey = formatDate(date: selectedDate)
        return meals[dateKey] ?? [:]
    }

    private func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
