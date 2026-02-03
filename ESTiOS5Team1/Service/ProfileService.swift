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
    /// 프로필을 생성합니다.
    ///
    /// - Endpoint:
    ///   `POST /profile`
    ///
    /// - Parameters:
    ///   - nickname: 사용자 닉네임
    ///   - avatarUrl: 아바타 URL 문자열
    ///
    /// - Returns:
    ///   `ProfileResponse`
    ///
    /// - Throws:
    ///   인증 오류 / 네트워크 오류 / 서버 응답 오류 / 디코딩 오류
    func create(nickname: String, avatarUrl: String) async throws -> ProfileResponse
    /// 프로필을 조회합니다.
    ///
    /// - Endpoint:
    ///   `GET /profile`
    ///
    /// - Returns:
    ///   `ProfileResponse`
    ///
    /// - Throws:
    ///   인증 오류 / 네트워크 오류 / 서버 응답 오류 / 디코딩 오류
    func fetch() async throws -> ProfileResponse
    /// 프로필을 수정합니다.
    ///
    /// - Endpoint:
    ///   `PATCH /profile`
    ///
    /// - Parameters:
    ///   - nickname: 수정할 닉네임
    ///   - avatarUrl: 수정할 아바타 URL 문자열
    ///
    /// - Returns:
    ///   `ProfileResponse`
    ///
    /// - Throws:
    ///   인증 오류 / 네트워크 오류 / 서버 응답 오류 / 디코딩 오류
    func update(nickname: String, avatarUrl: String) async throws -> ProfileResponse
}

/// 프로필 API의 실제 네트워크 구현체입니다.
final class ProfileServiceManager: ProfileService {

    private let tokenstore: TokenStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// 의존성을 주입해 서비스 인스턴스를 생성합니다.
    ///
    /// - Parameters:
    ///   - tokenstore: 인증 토큰 저장소
    init(tokenstore: TokenStore = .shared) {
        self.tokenstore = tokenstore
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    /// 프로필 생성 요청을 전송합니다.
    func create(nickname: String, avatarUrl: String) async throws -> ProfileResponse {
        // 토큰 포함 요청 + JSON 바디 구성
        var request = try authorizedRequest(url: ProfileEndpoint.create.url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(ProfileRequest(nickname: nickname, avatarUrl: avatarUrl))
        return try await perform(request)
    }

    /// 프로필 조회 요청을 전송합니다.
    func fetch() async throws -> ProfileResponse {
        let request = try authorizedRequest(url: ProfileEndpoint.fetch.url, method: "GET")
        return try await perform(request)
    }

    /// 프로필 수정 요청을 전송합니다.
    func update(nickname: String, avatarUrl: String) async throws -> ProfileResponse {
        // 프로필 수정은 PATCH로 처리
        var request = try authorizedRequest(url: ProfileEndpoint.update.url, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(ProfileRequest(nickname: nickname, avatarUrl: avatarUrl))
        return try await perform(request)
    }

    /// Bearer 토큰이 포함된 인증 요청 객체를 생성합니다.
    ///
    /// - Parameters:
    ///   - url: 요청 URL
    ///   - method: HTTP 메서드
    ///
    /// - Returns:
    ///   Authorization 헤더가 포함된 `URLRequest`
    ///
    /// - Throws:
    ///   Access Token이 없을 때 `URLError.badServerResponse`
    private func authorizedRequest(url: URL, method: String) throws -> URLRequest {
        guard let token = tokenstore.accessToken() else {
            throw URLError(.badServerResponse)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// 공통 요청 실행/상태코드 검증/디코딩을 처리합니다.
    ///
    /// - Parameters:
    ///   - request: 실행할 URLRequest
    ///
    /// - Returns:
    ///   `ProfileResponse`
    ///
    /// - Throws:
    ///   네트워크 오류 / 서버 응답 오류 / 디코딩 오류
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
