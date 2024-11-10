import SwiftUI

struct MeasureFoodView: View {
    @State private var searchQuery: String = ""
    @State private var foodResults: [FoodItem] = []
    @State private var selectedCategory: String = "01"
    @State private var isLoading: Bool = false
    @State private var cachedResults: [String: [FoodItem]] = [:]

    // Store meals by date and meal type
    @State private var meals: [String: [String: [(String, [String: Double])]]] = [:]
    @State private var selectedMealType: String = "아침" // Default selected meal type
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
            .navigationBarBackButtonHidden(true) // Hide default back button
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

    // MARK: - Functions

    private func setDefaultMealTypeBasedOnTime() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<11:
            selectedMealType = "아침" // Morning
        case 11..<17:
            selectedMealType = "점심" // Lunch
        default:
            selectedMealType = "저녁" // Dinner
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

    private func addToMeal(foodName: String, nutrients: [String: Double]) {
        // Ensure that meals[selectedMealType] exists, otherwise create it as an empty dictionary
        if meals[selectedMealType] == nil {
            meals[selectedMealType] = [:]
        }
        
        // Append the food name and nutrients tuple to the dictionary
        meals[selectedMealType]?[foodName, default: []].append((foodName, nutrients))
    }
}
