//
//  ContentView.swift
//  FitMeal
//
//  Created by 이수겸 on 10/1/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {

            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            MyPageView()
                .tabItem {
                    Label("My Page", systemImage: "person.fill")
                }
        }
    }
}
