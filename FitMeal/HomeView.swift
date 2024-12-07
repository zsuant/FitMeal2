import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("FitMeal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 40)
                    
                    HomeGridItem(title: "식단 추가", color: .blue, destination: MeasureFoodView(), icon: "plus.circle")
                    
                    HomeGridItem(title: "식단 확인", color: .green, destination: TodayIntakeView(), icon: "list.bullet")
                    
                    HomeGridItem(title: "나만의 식단 만들기", color: .orange, destination: CustomDietView(), icon: "star.fill")
                    
                    HomeGridItem(title: "영양성분 검색", color: .purple, destination: FoodNutritionalInfoView(), icon: "magnifyingglass")
                }
                .padding(.horizontal)
                .navigationTitle("홈")
            }
        }
    }
}

struct HomeGridItem<Destination: View>: View {
    let title: String
    let color: Color
    let destination: Destination
    let icon: String
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding()
            .frame(height: 80)
            .background(color)
            .cornerRadius(15)
            .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
}
