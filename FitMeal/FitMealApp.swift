//
//  FitMealApp.swift
//  FitMeal
//
//  Created by 이수겸 on 10/1/24.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct FitMealApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var isLoggedIn: Bool = false // 로그인 상태 관리

    var body: some Scene {
        WindowGroup {
            NavigationView {
                if isLoggedIn {
                    ContentView() // 로그인된 경우 홈페이지로 이동
                } else {
                    LoginView(isLoggedIn: $isLoggedIn) // 로그인되지 않은 경우 로그인 화면 표시
                }
            }
        }
    }
}
