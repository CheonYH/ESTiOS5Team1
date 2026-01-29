//
//  ProfileService.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/23/26.
//

import Foundation

/// 프로필 관련 API 엔드포인트 정의입니다.
enum ProfileEndpoint {
    case create
    case fetch
    case update

    var path: String {
        switch self {
            case .create, .fetch, .update:
                return "/profile"
        }
    }

    var url: URL {
        APIEnvironment.baseURL.appendingPathComponent(path)
    }
}

/// 프로필 API 계약입니다.
protocol ProfileService: Sendable {
    func create(nickname: String, avatarUrl: String) async throws -> ProfileResponse
    func fetch() async throws -> ProfileResponse
    func update(nickname: String, avatarUrl: String) async throws -> ProfileResponse
}

/// 프로필 API의 실제 네트워크 구현체입니다.
final class ProfileServiceManager: ProfileService {

    private let tokenstore: TokenStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(tokenstore: TokenStore = .shared) {
        self.tokenstore = tokenstore
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    func create(nickname: String, avatarUrl: String) async throws -> ProfileResponse {
        // 토큰 포함 요청 + JSON 바디 구성
        var request = try authorizedRequest(url: ProfileEndpoint.create.url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(ProfileRequest(nickname: nickname, avatarUrl: avatarUrl))
        return try await perform(request)
    }

    func fetch() async throws -> ProfileResponse {
        let request = try authorizedRequest(url: ProfileEndpoint.fetch.url, method: "GET")
        return try await perform(request)
    }

    func update(nickname: String, avatarUrl: String) async throws -> ProfileResponse {
        // 프로필 수정은 PATCH로 처리
        var request = try authorizedRequest(url: ProfileEndpoint.update.url, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(ProfileRequest(nickname: nickname, avatarUrl: avatarUrl))
        return try await perform(request)
    }

    private func authorizedRequest(url: URL, method: String) throws -> URLRequest {
        guard let token = tokenstore.accessToken() else {
            throw URLError(.badServerResponse)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func perform(_ request: URLRequest) async throws -> ProfileResponse {
        // 공통 네트워크 수행/검증 로직
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<empty>"
            print("[ProfileService] status=\(httpResponse.statusCode) body=\(body)")
            throw URLError(.badServerResponse)
        }

        return try decoder.decode(ProfileResponse.self, from: data)
    }
}
