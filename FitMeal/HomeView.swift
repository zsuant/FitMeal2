//
//  HomeView.swift
//  FitMeal
//
//  Created by 이수겸 on 10/1/24.
//


import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
            
            LazyVGrid(columns: columns, spacing: 20) {
                NavigationLink(destination: MeasureFoodView()) {
                    Text("식단 추가")
                        .frame(width: 150, height: 150)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .font(.headline)
                }
                
                NavigationLink(destination: TodayIntakeView()) {
                    Text("식단 확인")
                        .frame(width: 150, height: 150)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .font(.headline)
                }
                
                NavigationLink(destination: CustomDietView()) {
                    Text("나만의 식단 만들기")
                        .frame(width: 150, height: 150)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .font(.headline)
                }
                
                NavigationLink(destination: FoodNutritionalInfoView()) {
                    Text("영양성분 검색")
                        .frame(width: 150, height: 150)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .font(.headline)
                }
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}
