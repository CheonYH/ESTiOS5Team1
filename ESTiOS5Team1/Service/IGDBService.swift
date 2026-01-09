import Foundation

enum IGDBEndpoint: String {
    case games
    case genres
    case platforms
    case ageRatings = "age_ratings"
    case releaseDates = "release_dates"
}

/// IGDB API와 통신하기 위한 서비스 프로토콜입니다.
///
/// ViewModel은 이 프로토콜에만 의존하며,
/// 실제 네트워크 구현(`IGDBServiceManager`)과 분리되어 있습니다.
///
/// - Note:
/// 테스트(Mock Service)나 구현 변경 시
/// ViewModel 코드를 수정하지 않기 위해 사용됩니다.
protocol IGDBService {
    func fetch(_ batch: [(name: String, endpoint: IGDBEndpoint, query: String)]) async throws -> [String: [[String: Any]]]
}

/// IGDB API와 실제로 통신하는 서비스 구현체입니다.
///
/// 네트워크 요청, 인증 헤더 설정,
/// 응답 디코딩까지의 책임을 담당합니다.
///
/// - Important:
/// 이 클래스는 **데이터 가공을 하지 않습니다.**
/// DTO → Entity 변환은 ViewModel 또는 Entity 단계에서 수행합니다.
final class IGDBServiceManager: IGDBService {

    func fetch(_ batch: [(name: String, endpoint: IGDBEndpoint, query: String)]) async throws -> [String: [[String: Any]]] {

        let body = batch.map { block in
            """
            query \(block.endpoint.rawValue) \"\(block.name)\" {
                \(block.query)
            };
            """
        }.joined(separator: "\n")

        // print("📤 IGDB Multiquery Body:\n\(body)\n")

        var request = URLRequest(url: URL(string: "https://api.igdb.com/v4/multiquery")!)
        request.httpMethod = "POST"
        request.httpBody = Data(body.utf8)

        request.setValue(IGDBConfig.clientID, forHTTPHeaderField: "Client-ID")
        request.setValue("Bearer \(IGDBConfig.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse {
            print("📥 HTTP Status:", http.statusCode)
        }

        if let json = String(data: data, encoding: .utf8) {
            print("📥 Raw Response JSON:\n\(json)\n")
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        var result: [String: [[String: Any]]] = [:]

        for item in arr {
            if let name = item["name"] as? String,
               let block = item["result"] as? [[String: Any]] {
                result[name] = block
            }
        }

        return result
    }

}
