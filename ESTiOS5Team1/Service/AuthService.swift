//
//  AuthService.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation

// MARK: - API Environment

/// 백엔드 서버 환경 설정
///
/// - Usage:
///     APIEnvironment.baseURL
///
/// - Note:
///     추후 개발/스테이징/프로덕션 환경이 분리될 수 있으므로
///     Base URL은 별도 구조체로 관리한다.
enum APIEnvironment {
    /// 현재 사용하는 서버의 Base URL
    static let baseURL = URL(string: "https://port-0-ios5team-mk6rdyqw52cca57c.sel3.cloudtype.app")!
}

// MARK: - Auth Endpoints

/// 인증(Auth) 관련 API Endpoint 모음
///
/// - API Spec:
///     `POST /auth/login`
///     `POST /auth/refresh`
///
/// - Usage:
///     let url = AuthEndpoint.login.url
enum AuthEndpoint {
    case login
    case refresh

    /// API Path
    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .refresh: return "/auth/refresh"
        }
    }

    /// 최종 요청 URL 구성
    var url: URL {
        APIEnvironment.baseURL.appendingPathComponent(path)
    }
}

// MARK: - Auth Service Protocol

/// Auth 도메인 서비스 인터페이스
///
/// - Responsibilities:
///     - 로그인 요청
///     - Refresh Token 기반 토큰 갱신
///
/// - Design:
///     ViewModel 또는 상위 계층은 본 프로토콜에 의존하며,
///     실제 네트워크 구현체(AuthServiceImpl)와 분리된다.
///
/// - Token Handling:
///     성공 시 Access/Refresh Token 저장 책임은 구현체에 있음
protocol AuthService: Sendable {

    /// 로그인 요청
    ///
    /// - Endpoint:
    ///     `POST /auth/login`
    ///
    /// - Parameters:
    ///     - email: 사용자 이메일
    ///     - password: 사용자 비밀번호
    ///
    /// - Returns:
    ///     `LoginResponse` (Access/Refresh Token 포함)
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 오류 / 인증 실패
    func login(email: String, password: String) async throws -> LoginResponse

    /// Refresh Token 기반 토큰 갱신
    ///
    /// - Endpoint:
    ///     `POST /auth/refresh`
    ///
    /// - Returns:
    ///     `TokenPair` (Access/Refresh Token)
    ///
    /// - Note:
    ///     Refresh Token이 저장돼 있어야 호출 가능
    ///
    /// - Discardable Result:
    ///     UI가 반환값을 사용하지 않는 경우가 있어 discardable 처리
    @discardableResult
    func refresh() async throws -> TokenPair
}

// MARK: - Auth Service Implementation

/// 실제 인증 API와 통신하는 구현체
///
/// - Responsibilities:
///     - 로그인 요청 처리
///     - Refresh Token을 이용한 토큰 재발급
///     - Keychain에 토큰 저장
///
/// - Important:
///     본 클래스는 데이터 가공을 하지 않으며,
///     순수하게 서버 통신과 토큰 저장만 담당한다.
final class AuthServiceImpl: AuthService {

    /// 로그인 요청
    ///
    /// - Request Body:
    ///     `LoginRequest`
    ///
    /// - Response Body:
    ///     `LoginResponse`
    ///
    /// - Token Handling:
    ///     Access/Refresh Token을 Keychain에 저장하여 자동 로그인 가능
    func login(email: String, password: String) async throws -> LoginResponse {
        let url = AuthEndpoint.login.url
        let requestBody = LoginRequest(email: email, password: password)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard http.statusCode == 200 else {
            throw URLError(.userAuthenticationRequired)
        }

        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)

        /// Token 저장 (Access + Refresh)
        TokenStore.shared.updateTokens(response: decoded)

        return decoded
    }

    /// Refresh Token 기반 토큰 재발급
    ///
    /// - Request Body:
    ///     `RefreshRequest(refreshToken)`
    ///
    /// - Response Body:
    ///     `TokenPair`
    ///
    /// - Token Handling:
    ///     Rotation 정책 적용 시 Refresh Token도 함께 교체됨
    @discardableResult
    func refresh() async throws -> TokenPair {

        guard let refreshToken = TokenStore.shared.refreshToken() else {
            throw URLError(.userAuthenticationRequired)
        }

        let url = AuthEndpoint.refresh.url
        let requestBody = RefreshRequest(refreshToken: refreshToken)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard http.statusCode == 200 else {
            throw URLError(.userAuthenticationRequired)
        }

        let tokenPair = try JSONDecoder().decode(TokenPair.self, from: data)

        /// Token Rotation 적용 (Access + Refresh 갱신)
        TokenStore.shared.updateTokens(response: tokenPair)

        return tokenPair
    }
}
