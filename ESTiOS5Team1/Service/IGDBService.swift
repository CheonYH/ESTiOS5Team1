//
//  IGDBService.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation

/// IGDB API와 통신하기 위한 서비스 인터페이스입니다.
///
/// ViewModel은 이 프로토콜에만 의존하며,
/// 실제 네트워크 구현체와 분리되어 테스트 및 확장이 가능하도록 설계되었습니다.
protocol IGDBService {

    /// IGDB로부터 게임 목록을 조회합니다.
    ///
    /// - Returns: IGDB API 응답을 디코딩한 게임 DTO 배열
    /// - Throws:
    ///   - `URLError`: 네트워크 요청 실패 또는 서버 응답 오류 시
    ///   - `DecodingError`: 응답 데이터 디코딩 실패 시
    func fetchGameList() async throws -> [IGDBGameListDTO]
}

/// IGDB API와 실제로 통신하는 서비스 구현체입니다.
///
/// `/v4/games` 엔드포인트를 사용하여 게임 목록을 조회하며,
/// Swift Concurrency(`async/await`) 기반으로 네트워크 요청을 수행합니다.
final class IGDBServiceManager: IGDBService {

    /// IGDB 게임 목록을 비동기적으로 조회합니다.
    ///
    /// - Important:
    /// 이 메서드는 **네트워크 계층의 책임만 수행**하며,
    /// 데이터 가공이나 UI 친화적인 변환은 상위 계층(Entity / ViewModel)에서 처리합니다.
    func fetchGameList() async throws -> [IGDBGameListDTO] {

        let url = URL(string: "https://api.igdb.com/v4/games")!
        var request = URLRequest(url: url)

        /// IGDB API Query Language(APICALYPSE) 본문
        /// - 조회 필드: id, name, cover.image_id, rating, genres.name
        /// - 제한 개수: 5개
        let body = """
        fields id, name, cover.image_id, rating, genres.name; limit 5;
        """

        request.httpBody = Data(body.utf8)

        request.httpMethod = "POST"

        // IGDB 인증 헤더
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

        let (data, response) = try await URLSession.shared.data(for: request)

        // HTTP 응답 검증
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // 응답 데이터 디코딩
        return try JSONDecoder().decode([IGDBGameListDTO].self, from: data)
    }
}
