//
//  IGDBService.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation

enum IGDBEndpoint: String {
    case games
    case genres
    case platforms
    case ageRatings = "age_ratings"
    case releaseDates = "release_dates"
}

struct IGDBBatchItem: Sendable {
    let name: String
    let endpoint: IGDBEndpoint
    let query: String
}

typealias IGDBRawResponse = [String: [[String: Any]]]

protocol IGDBService {
    func fetch(_ batch: [IGDBBatchItem]) async throws -> IGDBRawResponse
    func fetchDetail(id: Int) async throws -> IGDBGameListDTO
}

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
