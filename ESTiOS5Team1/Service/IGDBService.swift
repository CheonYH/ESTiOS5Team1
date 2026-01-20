//
//  IGDBService.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation

/// IGDB API에서 사용하는 엔드포인트 목록입니다.
///
/// 쿼리 구성 시 이 enum을 기준으로 endpoint를 지정합니다.
enum IGDBEndpoint: String {
    case games
    case genres
    case platforms
    case releaseDates = "release_dates"
}

/// multiquery 요청 한 블록을 표현합니다.
///
/// name은 응답에서 섹션 키로 그대로 사용됩니다.
struct IGDBBatchItem: Sendable {
    let name: String
    let endpoint: IGDBEndpoint
    let query: String
}

typealias IGDBRawResponse = [String: [[String: Any]]]

/// IGDB 요청을 추상화한 인터페이스입니다.
///
/// ViewModel은 이 프로토콜에 의존합니다.
protocol IGDBService {
    func fetch(_ batch: [IGDBBatchItem]) async throws -> IGDBRawResponse
    func fetchDetail(id: Int) async throws -> IGDBGameListDTO
}

/// IGDB multiquery 요청을 수행하는 서비스 구현체입니다.
///
/// 서버 프록시를 통해 IGDB와 통신합니다.
final class IGDBServiceManager: IGDBService {

    private let baseURL = "https://port-0-ios5team-mk6rdyqw52cca57c.sel3.cloudtype.app"

    func fetch(_ batch: [IGDBBatchItem]) async throws -> IGDBRawResponse {

        let body = batch.map { block in
            """
            query \(block.endpoint.rawValue) \"\(block.name)\" {
                \(block.query)
            };
            """
        }.joined(separator: "\n")

        guard let url = URL(string: "\(baseURL)/v4/multiquery") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(body.utf8)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
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

    func fetchDetail(id: Int) async throws -> IGDBGameListDTO {
        let query = IGDBQuery.detail + "where id = \(id);"

        guard let url = URL(string: "\(baseURL)/v4/games") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(query.utf8)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        guard let raw = arr.first else { throw URLError(.cannotDecodeContentData) }

        let dtoData = try JSONSerialization.data(withJSONObject: raw, options: [])
        return try JSONDecoder().decode(IGDBGameListDTO.self, from: dtoData)
    }
}
