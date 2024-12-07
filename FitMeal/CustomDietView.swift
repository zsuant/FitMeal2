import SwiftUI

struct CustomDietView: View {
    @State private var searchQuery: String = ""
    @State private var foodResults: [FoodItem] = []
    @State private var selectedCategory: String = "01"
    @State private var isLoading: Bool = false
    @State private var cachedResults: [String: [FoodItem]] = [:]
    
    @State private var dietName: String = ""
    @State private var isEnteringDietName = true
    
    @State private var meals: [(String, [String: Double])] = []
    @State private var totalNutrients: [String: Double] = [:]
    
    // 나만의 식단 저장
    @State private var customDietFoods: [FoodItem] = []
    
    // New state for showing success message
    @State private var isDietAdded: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isEnteringDietName {
                    dietNameInputField
                } else {
                    searchField
                    categorySelection
                    
                    if isLoading {
                        ProgressView("로딩 중...")
                    } else {
                        foodResultsList
                    }
                    
                    addedMealsSummary
                    
                    // Show success message when diet is added
                    if isDietAdded {
                        Text("식단이 추가되었습니다!")
                            .font(.headline)
                            .foregroundColor(.green)
                            .padding()
                            .transition(.opacity)
                            .animation(.easeInOut, value: isDietAdded)
                    }
                }
            }
            .navigationTitle("나만의 식단 만들기")
            .navigationBarBackButtonHidden(true)
            .padding(.bottom, 10)
            .onAppear {
                loadInitialFoodData()
            }
        }
    }
    
    // MARK: - View Components
    
    private var dietNameInputField: some View {
        VStack {
            TextField("식단 이름을 입력하세요", text: $dietName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("다음") {
                isEnteringDietName = false
            }
            .padding()
            .disabled(dietName.isEmpty)
        }
    }
    
    private var searchField: some View {
        TextField("음식 검색", text: $searchQuery)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .onChange(of: searchQuery) { _ in
                filterFoodResults()
            }
    }
    
    private var categorySelection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(FoodAPI.categories, id: \.code) { category in
                    Button(action: {
                        selectedCategory = category.code
                        if let cached = cachedResults[category.code] {
                            foodResults = cached
                        } else {
                            fetchFoodNutritionalInfo()
                        }
                    }) {
                        Text(category.name)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category.code ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(selectedCategory == category.code ? Color.blue : Color.gray, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var foodResultsList: some View {
        List(foodResults, id: \.foodName) { item in
            NavigationLink(destination: WeightInputView(item: item, onAddToMeal: addToMeal)) {
                FoodItemView(item: item)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var addedMealsSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(dietName) - 추가된 음식 목록")
                .font(.headline)
                .padding(.top)
                .padding(.leading, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(meals, id: \.0) { foodName, nutrients in
                        HStack {
                            Text(foodName)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Text("\(nutrients["칼로리"] ?? 0, specifier: "%.2f") kcal")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }
                    
                    if !totalNutrients.isEmpty {
                        Divider()
                            .padding(.horizontal)
                        
                        Text("총 영양성분")
                            .font(.headline)
                            .padding(.top, 5)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(totalNutrients.keys.sorted(), id: \.self) { nutrient in
                                HStack {
                                    Text("\(nutrient):")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(totalNutrients[nutrient] ?? 0, specifier: "%.2f")")
                                        .font(.subheadline)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .padding(.vertical)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
        .frame(maxWidth: .infinity, maxHeight: 300)
        .padding(.horizontal)
        .overlay(
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Button(action: {
                        saveCustomDiet()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 10)
                    .padding(.bottom, 10)
                }
            }
        )
    }
    
    // MARK: - Functions
    
    private func loadInitialFoodData() {
        if cachedResults[selectedCategory] == nil {
            fetchFoodNutritionalInfo()
        } else {
            foodResults = cachedResults[selectedCategory]!
        }
    }
    
    private func fetchFoodNutritionalInfo() {
        isLoading = true
        FoodAPI.fetchFoodNutritionalInfo(for: selectedCategory) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let items):
                    self.foodResults = items
                    self.cachedResults[self.selectedCategory] = items
                case .failure(let error):
                    print("Error fetching data: \(error)")
                }
            }
        }
    }
    
    private func filterFoodResults() {
        if searchQuery.isEmpty {
            foodResults = cachedResults[selectedCategory] ?? []
        } else {
            foodResults = (cachedResults[selectedCategory] ?? []).filter {
                $0.foodName.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
    
    private func addToMeal(foodName: String, nutrients: [String: Double]) {
        meals.append((foodName, nutrients))
        
        for (nutrient, value) in nutrients {
            totalNutrients[nutrient, default: 0] += value
        }
    }
    
    private func saveCustomDiet() {
        customDietFoods = meals.map {
            FoodItem(
                foodName: $0.0,
                calories: $0.1["칼로리"] ?? 0,
                carbs: $0.1["탄수화물"] ?? 0,
                protein: $0.1["단백질"] ?? 0,
                fat: $0.1["지방"] ?? 0,
                saturatedFat: $0.1["포화지방"] ?? 0,
                sodium: $0.1["나트륨"] ?? 0,
                sugar: $0.1["당"] ?? 0
            )
        }
        print("나만의 식단이 저장되었습니다: \(customDietFoods)")
        
        // Show success message and hide it after 2 seconds
        isDietAdded = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isDietAdded = false
        }
    }
}
