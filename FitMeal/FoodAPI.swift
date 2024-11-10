import Foundation
import Combine



// FoodAPI 클래스 정의
class FoodAPI {
    static let shared = FoodAPI() // Singleton 인스턴스
    private var cancellable: AnyCancellable?

    // 카테고리 데이터
    static let categories: [(code: String, name: String)] = [
        ("01", "밥류"), ("02", "빵 및 과자류"), ("03", "면 및 만두류"),
        ("04", "죽 및 스프류"), ("05", "국 및 탕류"), ("06", "찌개 및 전골류"),
        ("07", "찜류"), ("08", "구이류"), ("09", "전적 및 부침류"),
        ("10", "볶음류"), ("11", "조림류"), ("12", "튀김류"),
        ("13", "나물숙채류"), ("14", "생채무침류"), ("15", "김치류"),
        ("16", "젓갈류"), ("17", "장아찌 절임류"), ("18", "소스류"),
        ("19", "유제품 및 빙과류"), ("20", "음료 및 차류"),
        ("24", "곡류 서류 제품"), ("25", "두류 견과 및 종실류"), ("27", "수조어육류")
    ]

    static func fetchFoodNutritionalInfo(for category: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        let apiKey = "8zxlS7roLbWluRaSyKAOX46tEMOEQQMAfY3sfDjIC2uGJv40SrUTfEnQEq55eUVOcelukk5pRNb0RCqMD5nCiw%3D%3D"
        let urlString = "http://api.data.go.kr/openapi/tn_pubr_public_nutri_food_info_api?serviceKey=\(apiKey)&foodLv3Cd=\(category)&pageNo=1&numOfRows=100&type=json"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let sessionDelegate = SSLSessionDelegate()
        let session = URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: nil)

        // Combine 사용하여 API 호출
        shared.cancellable = session.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: NutritionResponse.self, decoder: JSONDecoder())
            .map { response in
                response.response.body.items.map { item in
                    FoodItem(
                        foodName: item.foodNm,
                        calories: Double(item.enerc) ?? 0,
                        carbs: Double(item.chocdf) ?? 0,
                        protein: Double(item.prot) ?? 0,
                        fat: Double(item.fatce) ?? 0,
                        saturatedFat: Double(item.fasat) ?? 0, // 포화지방
                        sodium: Double(item.nat) ?? 0,
                        sugar: Double(item.sugar) ?? 0 // 당
                    )
                }
            }
            .sink(receiveCompletion: { completionStatus in
                if case .failure(let error) = completionStatus {
                    print("Error fetching data: \(error)")
                    completion(.failure(error))
                }
            }, receiveValue: { items in
                completion(.success(items))
            })
    }
}

// URLSessionDelegate 클래스 SSL 인증 문제 해결용
class SSLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }
}
