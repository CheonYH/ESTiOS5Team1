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
///     `POST /auth/register`
///
/// - Usage:
///     let url = AuthEndpoint.login.url
enum AuthEndpoint {
    case login
    case refresh
    case register

    /// API Path
    var path: String {
        switch self {
            case .login: return "/auth/login"
            case .refresh: return "/auth/refresh"
            case .register: return "/auth/register"
        }
    }

    /// 최종 요청 URL 구성
    var url: URL {
        APIEnvironment.baseURL.appendingPathComponent(path)
    }
}

// MARK: - Auth Service Protocol

/// 인증(Auth) 도메인 서비스 인터페이스입니다.
///
/// - Purpose:
///     ViewModel에서 인증 관련 작업을 수행하기 위한 추상화입니다.
///
/// - Responsibilities:
///     - 로그인
///     - 회원가입
///     - Refresh 토큰 기반 재발급
///
/// - Important:
///     상위 계층은 본 프로토콜에 의존하고, 실제 네트워크 구현은 `AuthServiceImpl`이 담당합니다.
///
/// - Token Handling:
///     성공 시 Access/Refresh Token 저장 책임은 구현체에 있습니다.
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
    ///     Refresh Token이 저장돼 있어야 호출 가능합니다. UI에서 반환값을 사용하지 않을 수 있으므로 discardable로 처리했습니다.
    ///
    /// - Example:
    ///     `let tokens = try await authService.refresh()`
    @discardableResult
    func refresh() async throws -> TokenPair

    /// 회원가입 요청
    ///
    /// - Endpoint:
    ///     `POST /auth/register`
    ///
    /// - Parameters:
    ///     - email: 사용자 이메일
    ///     - password: 사용자 비밀번호
    ///     - nickname: 표시할 닉네임
    ///
    /// - Returns:
    ///     `RegisterResponse` (성공 여부 및 메시지)
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 오류 / 검증 실패(`AuthError.validation` 등)
    func register(email: String, password: String, nickname: String) async throws -> RegisterResponse
}

// MARK: - Auth Service Implementation

/// 인증 API와 통신하는 구현체입니다.
///
/// - Purpose:
///     서버와의 통신 및 토큰 저장을 담당합니다.
///
/// - Responsibilities:
///     - 로그인 요청 처리
///     - Refresh 토큰 재발급
///     - Keychain 토큰 저장
///
/// - Important:
///     데이터 가공 없이 순수 네트워크/저장만 담당합니다.
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

        switch http.statusCode {
        case 200:
            let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
            TokenStore.shared.updateTokens(response: decoded)
            return decoded

        case 401:
            throw AuthError.invalidCredentials

        case 409:
            throw AuthError.conflict("email")

        case 422:
            throw AuthError.validation("입력 형식을 확인해주세요.")

        case 500...599:
            throw AuthError.server

        default:
            throw AuthError.server
        }


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

        switch http.statusCode {
        case 200:
            let tokenPair = try JSONDecoder().decode(TokenPair.self, from: data)
            TokenStore.shared.updateTokens(response: tokenPair)
            return tokenPair

        case 401:
            throw AuthError.invalidCredentials // 즉 토큰 만료 → logout

        default:
            throw AuthError.server
        }

    }

    /// 회원가입 요청
    ///
    /// - Request Body:
    ///     `RegisterRequest`
    ///
    /// - Response Body:
    ///     `RegisterResponse`
    ///
    /// - Validation:
    ///     서버가 `success == false` 또는 검증 에러를 반환하면
    ///     `AuthError.validation`으로 매핑하여 throw 합니다.
    func register(email: String, password: String, nickname: String) async throws -> RegisterResponse {

        let url = AuthEndpoint.register.url
        let requestBody = RegisterRequest(email: email, password: password, nickname: nickname)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.server
        }

        // --- 1. Status Code 체크 (네트워크 레벨)
        switch http.statusCode {
        case 200:
            break  // Payload 검사로 넘어감

        case 400...499:
            throw AuthError.validation("잘못된 요청입니다.")

        case 500...599:
            throw AuthError.server

        default:
            throw AuthError.server
        }

        // --- 2. Payload 검사 (도메인 레벨)
        let decoded = try JSONDecoder().decode(RegisterResponse.self, from: data)

        if decoded.success == false {
            throw AuthError.validation(decoded.message)
        }

        return decoded
    }

}
