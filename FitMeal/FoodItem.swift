//
//  FoodItem.swift
//  FitMeal
//
//  Created by 이수겸 on 11/2/24.
//

import Foundation
import Combine

struct FoodItem {
    let foodName: String
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    let saturatedFat: Double // 포화지방
    let sodium: Double
    let sugar: Double // 당
}

// NutritionResponse and other necessary structs
struct NutritionResponse: Codable {
    let response: ResponseBody
}

struct ResponseBody: Codable {
    let body: ResponseBodyContent
}

struct ResponseBodyContent: Codable {
    let items: [NutritionItem]
}

struct NutritionItem: Codable {
    let foodNm: String
    let enerc: String
    let chocdf: String
    let prot: String
    let fatce: String
    let nat: String
    let fasat: String // 포화지방
    let sugar: String // 당

    enum CodingKeys: String, CodingKey {
        case foodNm
        case enerc
        case chocdf
        case prot
        case fatce
        case nat
        case fasat
        case sugar
    }
}
