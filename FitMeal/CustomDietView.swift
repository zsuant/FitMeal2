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
                            .foregroundColor(.white) // Always white text
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
            }
            
            if !totalNutrients.isEmpty {
                Text("총 영양성분")
                    .font(.headline)
                    .padding(.top, 5)
                
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
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
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
        print("Added \(foodName) with nutrients: \(nutrients)")
    }
}
