import Foundation

/// IGDB API와 통신하기 위한 서비스 프로토콜입니다.
///
/// ViewModel은 이 프로토콜에만 의존하며,
/// 실제 네트워크 구현(`IGDBServiceManager`)과 분리되어 있습니다.
///
/// - Note:
/// 테스트(Mock Service)나 구현 변경 시
/// ViewModel 코드를 수정하지 않기 위해 사용됩니다.
protocol IGDBService {

    /// IGDB에서 게임 목록을 조회합니다.
    ///
    /// `/v4/games` 엔드포인트를 사용하며,
    /// APICALYPSE 쿼리를 문자열로 전달받습니다.
    ///
    /// - Parameter query: IGDB APICALYPSE 쿼리 문자열
    /// - Returns: 게임 목록 DTO 배열
    func fetchGameList(query: String) async throws -> [IGDBGameListDTO]

    /// IGDB에서 장르 목록을 조회합니다.
    ///
    /// `/v4/genres` 엔드포인트를 사용합니다.
    ///
    /// - Parameter query: 장르 조회용 APICALYPSE 쿼리 문자열
    /// - Returns: 장르 DTO 배열
    func fetchGenres(query: String) async throws -> [IGDBGenreDTO]
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

    /// 게임 목록 조회
    func fetchGameList(query: String) async throws -> [IGDBGameListDTO] {
        try await request(
            endpoint: "games",
            query: query
        )
    }

    /// 장르 목록 조회
    func fetchGenres(query: String) async throws -> [IGDBGenreDTO] {
        try await request(
            endpoint: "genres",
            query: query
        )
    }

    /// IGDB API 공통 요청 메서드
    ///
    /// - Note:
    /// games, genres 등 여러 엔드포인트에서
    /// 공통으로 사용하는 네트워크 요청 로직입니다.
    private func request<T: Decodable>(
        endpoint: String,
        query: String
    ) async throws -> [T] {

        let url = URL(string: "https://api.igdb.com/v4/\(endpoint)")!
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.httpBody = Data(query.utf8)

        // IGDB 인증 헤더
        request.setValue(IGDBConfig.clientID, forHTTPHeaderField: "Client-ID")
        request.setValue(
            "Bearer \(IGDBConfig.accessToken)",
            forHTTPHeaderField: "Authorization"
        )

        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([T].self, from: data)
    }
}
