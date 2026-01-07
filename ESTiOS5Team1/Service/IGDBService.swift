import Foundation

/// IGDB API와 통신하기 위한 서비스 프로토콜입니다.
///
/// ViewModel은 이 프로토콜에만 의존하며,
/// 실제 네트워크 구현과 분리되어 있습니다.
/// 이를 통해 테스트나 구현 변경이 쉬워집니다.
protocol IGDBService {

    /// IGDB에서 게임 목록을 조회합니다.
    ///
    /// - Parameter query: IGDB APICALYPSE 쿼리 문자열
    /// - Returns: 디코딩된 게임 DTO 배열
    /// - Throws:
    ///   - `URLError`: 네트워크 요청 실패 또는 서버 오류
    ///   - `DecodingError`: 응답 데이터 디코딩 실패
    func fetchGameList(query: String) async throws -> [IGDBGameListDTO]
}

/// IGDB API와 실제로 통신하는 서비스 구현체입니다.
///
/// `/v4/games` 엔드포인트를 사용하여
/// 게임 목록을 조회합니다.
final class IGDBServiceManager: IGDBService {

    /// IGDB 게임 목록을 비동기적으로 조회합니다.
    ///
    /// - Important:
    /// 이 메서드는 **네트워크 요청과 응답 처리만 담당**합니다.
    /// 데이터를 앱에서 사용하기 좋은 형태로 바꾸는 작업은
    /// `GameEntity`나 ViewModel에서 처리합니다.
    ///
    /// - Parameter query: IGDB APICALYPSE 쿼리 문자열
    func fetchGameList(query: String) async throws -> [IGDBGameListDTO] {

        let url = URL(string: "https://api.igdb.com/v4/games")!
        var request = URLRequest(url: url)

        // IGDB APICALYPSE 쿼리를 HTTP Body로 전달
        request.httpBody = Data(query.utf8)
        request.httpMethod = "POST"

        // IGDB 인증 헤더 설정
        request.setValue(
            IGDBConfig.clientID,
            forHTTPHeaderField: "Client-ID"
        )
        request.setValue(
            "Bearer \(IGDBConfig.accessToken)",
            forHTTPHeaderField: "Authorization"
        )

        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        // 네트워크 요청 수행
        let (data, response) = try await URLSession.shared.data(for: request)

        // HTTP 응답 상태 코드 확인
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // JSON 응답을 DTO 배열로 디코딩
        return try JSONDecoder().decode([IGDBGameListDTO].self, from: data)
    }
}
