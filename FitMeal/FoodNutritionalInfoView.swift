import SwiftUI
import Combine

struct FoodNutritionalInfoView: View {
    @State private var searchQuery: String = ""
    @State private var foodResults: [FoodItem] = []
    @State private var selectedCategory: String = "01"
    @State private var isLoading: Bool = false
    @State private var cachedResults: [String: [FoodItem]] = [:]

    var body: some View {
        NavigationView {
            VStack {
                // Search Field
                TextField("음식 검색", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchQuery) { _ in
                        filterFoodResults()
                    }

                // Category Selection View
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(FoodAPI.categories, id: \.code) { category in
                            Button(action: {
                                selectedCategory = category.code
                                if let cached = cachedResults[category.code] {
                                    foodResults = cached
                                } else {
                                    loadFoodData()
                                }
                            }) {
                                Text(category.name)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category.code ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(.white) // Consistent white text
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

                // Food Results List
                if isLoading {
                    ProgressView("로딩 중...")
                } else {
                    List(foodResults, id: \.foodName) { item in
                        NavigationLink(destination: FoodDetailView(item: item)) {
                            FoodItemView(item: item)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("영양성분 검색")
            .padding(.bottom, 10)
            .onAppear {
                if cachedResults[selectedCategory] == nil {
                    loadFoodData()
                } else {
                    foodResults = cachedResults[selectedCategory]!
                }
            }
        }
    }

    // MARK: - Functions
    
    private func loadFoodData() {
        isLoading = true
        FoodAPI.fetchFoodNutritionalInfo(for: selectedCategory) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let items):
                    foodResults = items
                    cachedResults[selectedCategory] = items // Save to cache
                case .failure(let error):
                    print("Error loading food data: \(error)")
                    // Additional error handling can be added here
                }
            }
        }
    }

    private func filterFoodResults() {
        if searchQuery.isEmpty {
            foodResults = cachedResults[selectedCategory] ?? []
        } else {
            foodResults = (cachedResults[selectedCategory] ?? []).filter { $0.foodName.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
}




struct FoodDetailView: View {
    let item: FoodItem

    // Define daily recommended intake values
    private let dailyCalorieIntake: Double = 2000
    private let dailyCarbsIntake: Double = 300
    private let dailyProteinIntake: Double = 50
    private let dailyFatIntake: Double = 70
    private let dailySaturatedFatIntake: Double = 20
    private let dailySodiumIntake: Double = 2300
    private let dailySugarIntake: Double = 50

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(item.foodName)
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            HStack {
                Text("칼로리:")
                Spacer()
                Text("\(item.calories, specifier: "%.2f") kcal")
                Text("(\(item.calories / dailyCalorieIntake * 100, specifier: "%.1f")%)")
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("탄수화물:")
                Spacer()
                Text("\(item.carbs, specifier: "%.2f") g")
                Text("(\(item.carbs / dailyCarbsIntake * 100, specifier: "%.1f")%)")
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("단백질:")
                Spacer()
                Text("\(item.protein, specifier: "%.2f") g")
                Text("(\(item.protein / dailyProteinIntake * 100, specifier: "%.1f")%)")
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("지방:")
                Spacer()
                Text("\(item.fat, specifier: "%.2f") g")
                Text("(\(item.fat / dailyFatIntake * 100, specifier: "%.1f")%)")
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("포화지방:")
                Spacer()
                Text("\(item.saturatedFat, specifier: "%.2f") g")
                Text("(\(item.saturatedFat / dailySaturatedFatIntake * 100, specifier: "%.1f")%)")
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("나트륨:")
                Spacer()
                Text("\(item.sodium, specifier: "%.2f") mg")
                Text("(\(item.sodium / dailySodiumIntake * 100, specifier: "%.1f")%)")
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("당:")
                Spacer()
                Text("\(item.sugar, specifier: "%.2f") g")
                Text("(\(item.sugar / dailySugarIntake * 100, specifier: "%.1f")%)")
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("영양 정보")
    }
}



struct FoodItemView: View {
    let item: FoodItem

    var body: some View {
        VStack(alignment: .leading) {
            Text(item.foodName)
                .font(.headline)
                .padding(.bottom, 2)

            Text("Calories: \(item.calories, specifier: "%.1f") kcal")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}
