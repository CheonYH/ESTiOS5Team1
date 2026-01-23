//
//  ReviewService.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation

enum ReviewEndpoint {
    case create
    case update(id: Int)
    case delete(id: Int)
    case fetchByGame(id: Int, sort: ReviewSortOption?)
    case stats(id: Int)
    case me

    /// API Path
    var path: String {
        switch self {
            case .create: return "/reviews"
            case .update(let id): return "/reviews/\(id)"
            case .delete(let id): return "/reviews/\(id)"
            case .fetchByGame(let gameId, _): return "/reviews/game/\(gameId)"
            case .stats(let gameId): return "/reviews/game/\(gameId)/stats"
            case .me: return "/reviews/me"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
            case .fetchByGame(_, let sort):
                if let sort { return [URLQueryItem(name: "sort", value: sort.rawValue)] }
                return nil
            default:
                return nil
        }
    }

    /// 최종 요청 URL 구성
    var url: URL {
        var components = URLComponents(url: APIEnvironment.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        return components.url!
    }
}

enum ReviewSortOption: String, Sendable {
    case latest
    case oldest
}

enum ReviewServiceError: Error {
    case unauthenticated          // 토큰 없음
    case invalidResponse          // HTTPURLResponse 캐스팅 실패
    case serverError(statusCode: Int) // 4xx, 5xx 등
}

protocol ReviewService {
    func create(gameId: Int, rating: Int, content: String) async throws -> ReviewResponse
    func update(id: Int, rating: Int?, content: String?) async throws
    func delete(id: Int) async throws
    func fetchByGame(gameId: Int, sort: ReviewSortOption?) async throws -> [ReviewResponse]
    func stats(gameId: Int) async throws -> ReviewStatsResponse
    func me() async throws -> [ReviewResponse]
}

final class ReviewServiceManager: ReviewService {

    private let tokenStore: TokenStore
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(tokenStore: TokenStore = .shared) {
        self.tokenStore = tokenStore

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder = encoder
    }

    func create(gameId: Int, rating: Int, content: String) async throws -> ReviewResponse {
        guard let token = tokenStore.accessToken() else {
            throw ReviewServiceError.unauthenticated
        }

        let endpoint = ReviewEndpoint.create
        var request = URLRequest(url: endpoint.url)

        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CreateReviewRequest(gameId: gameId, rating: rating, content: content)
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
            case 200 ..< 300:
                return try decoder.decode(ReviewResponse.self, from: data)
            case 401:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)

            default:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)
        }

    }

    func update(id: Int, rating: Int?, content: String?) async throws {
        guard let token = tokenStore.accessToken() else {
            throw ReviewServiceError.unauthenticated
        }

        let endpoint = ReviewEndpoint.update(id: id)
        var request = URLRequest(url: endpoint.url)

        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = UpdateReviewRequest(rating: rating, content: content)
        request.httpBody = try encoder.encode(body)

        let(_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
            case 200 ..< 300:
                return
            case 401:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)
            case 404:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    func delete(id: Int) async throws {
        guard let token = tokenStore.accessToken() else {
            throw ReviewServiceError.unauthenticated
        }

        let endpoint = ReviewEndpoint.delete(id: id)
        var request = URLRequest(url: endpoint.url)

        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
            case 200 ..< 300:
                return

            case 401:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)

            case 404:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)

            default:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    func fetchByGame(gameId: Int, sort: ReviewSortOption?) async throws -> [ReviewResponse] {
        let endpoint = ReviewEndpoint.fetchByGame(id: gameId, sort: sort)
        var request = URLRequest(url: endpoint.url)

        request.httpMethod = "GET"

        let(data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
            case 200 ..< 300:
                // 5) decode 배열 처리
                return try decoder.decode([ReviewResponse].self, from: data)

            default:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    func stats(gameId: Int) async throws -> ReviewStatsResponse {
        let endpoint = ReviewEndpoint.stats(id: gameId)
        var request = URLRequest(url: endpoint.url)

        request.httpMethod = "GET"

        let(data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
            case 200 ..< 300:
                return try decoder.decode(ReviewStatsResponse.self, from: data)

            default:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    func me() async throws -> [ReviewResponse] {
        guard let token = tokenStore.accessToken() else {
            throw ReviewServiceError.unauthenticated
        }

        let endpoint = ReviewEndpoint.me
        var request = URLRequest(url: endpoint.url)

        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
            case 200 ..< 300:
                return try decoder.decode([ReviewResponse].self, from: data)

            case 401:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)

            default:
                throw ReviewServiceError.serverError(statusCode: httpResponse.statusCode)
        }
    }

}
