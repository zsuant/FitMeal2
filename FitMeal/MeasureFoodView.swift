import SwiftUI

struct MeasureFoodView: View {
    @State private var searchQuery: String = ""
    @State private var foodResults: [FoodItem] = []
    @State private var selectedCategory: String = "01"
    @State private var isLoading: Bool = false
    @State private var cachedResults: [String: [FoodItem]] = [:]
    @State private var customFoods: [FoodItem] = [
        FoodItem(foodName: "식단1", calories: 227.5, carbs: 30, protein: 15, fat: 10, saturatedFat: 3, sodium: 200, sugar: 5)
    ]


    @State private var favoriteItems: Set<String> = [] // 즐겨찾기된 음식 이름 저장

    @State private var meals: [String: [String: [(String, [String: Double])]]] = [:]
    @State private var selectedMealType: String = "아침"
    private let mealTypes = ["아침", "점심", "저녁"]

    var body: some View {
        NavigationView {
            VStack {
                mealTypePicker

                searchField

                categorySelection

                if isLoading {
                    ProgressView("로딩 중...")
                } else {
                    foodResultsList
                }
            }
            .navigationTitle("영양성분 측정")
            .navigationBarBackButtonHidden(true)
            .padding(.bottom, 10)
            .onAppear {
                setDefaultMealTypeBasedOnTime()
                loadInitialFoodData()
            }
        }
    }

    // MARK: - View Components

    private var mealTypePicker: some View {
        Picker("식사 선택", selection: $selectedMealType) {
            ForEach(mealTypes, id: \.self) { mealType in
                Text(mealType).tag(mealType)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
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
                        if category.code == "custom" {
                            foodResults = customFoods
                            // '나만의 식단' 카테고리 선택 시 바로 식단에 추가
                            addCustomFoodsToMeal()
                        } else if let cached = cachedResults[category.code] {
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
        List {
            ForEach(sortedFoodResults, id: \.foodName) { item in
                HStack {
                    // NavigationLink는 텍스트와 아이콘을 감싸도록 수정
                    NavigationLink(destination: WeightInputView(item: item, onAddToMeal: addToMeal)) {
                        FoodItemView(item: item)
                    }
                    Spacer()
                    // 독립된 즐겨찾기 버튼
                    Button(action: {
                        toggleFavorite(for: item)
                    }) {
                        Image(systemName: favoriteItems.contains(item.foodName) ? "star.fill" : "star")
                            .foregroundColor(favoriteItems.contains(item.foodName) ? .yellow : .gray)
                    }
                    .buttonStyle(PlainButtonStyle()) // 버튼 스타일로 인해 링크처럼 보이지 않도록 설정
                }
            }
        }
        .listStyle(PlainListStyle())
    }


    // MARK: - Computed Properties

    private var sortedFoodResults: [FoodItem] {
        let favorites = foodResults.filter { favoriteItems.contains($0.foodName) }
        let nonFavorites = foodResults.filter { !favoriteItems.contains($0.foodName) }
        return favorites + nonFavorites
    }

    // MARK: - Functions

    private func setDefaultMealTypeBasedOnTime() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<11:
            selectedMealType = "아침"
        case 11..<17:
            selectedMealType = "점심"
        default:
            selectedMealType = "저녁"
        }
    }

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

    private func toggleFavorite(for item: FoodItem) {
        if favoriteItems.contains(item.foodName) {
            favoriteItems.remove(item.foodName)
        } else {
            favoriteItems.insert(item.foodName)
        }
    }

    private func addToMeal(foodName: String, nutrients: [String: Double]) {
        if meals[selectedMealType] == nil {
            meals[selectedMealType] = [:]
        }
        meals[selectedMealType]?[foodName, default: []].append((foodName, nutrients))
    }

    private func addCustomFoodsToMeal() {
        // '나만의 식단' 카테고리가 선택되었을 때 바로 customFoods를 식단에 추가
        for food in customFoods {
            addToMeal(foodName: food.foodName, nutrients: [
                "calories": food.calories,
                "carbs": food.carbs,
                "protein": food.protein,
                "fat": food.fat,
                "saturatedFat": food.saturatedFat,
                "sodium": food.sodium,
                "sugar": food.sugar
            ])
        }
    }
}
