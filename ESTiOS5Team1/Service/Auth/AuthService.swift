//
//  AuthService.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation
import Firebase
import GoogleSignIn
import FirebaseAuth

// MARK: - API Environment

/// Auth API의 베이스 URL을 한 곳에서 관리합니다.
///
/// 환경 분리 시 이 값을 바꾸면 전체 요청이 함께 바뀝니다.
enum APIEnvironment {
    /// 현재 사용하는 서버의 Base URL
    static let baseURL = URL(string: "https://port-0-ios5team-mk6rdyqw52cca57c.sel3.cloudtype.app")!
}

// MARK: - Auth Endpoints

/// Auth 엔드포인트를 모아둔 정의입니다.
///
/// 실제 경로가 바뀌면 이 enum을 기준으로 변경합니다.
enum AuthEndpoint {
    case login
    case refresh
    case register
    case nicknameCheck
    case socialLogin
    case socialRegister
    case firebaseConfig
    case deleteAccount
    case me
    case logout
    case onboardingComplete

    /// API Path
    var path: String {
        switch self {
            case .login: return "/auth/login"
            case .refresh: return "/auth/refresh"
            case .register: return "/auth/register"
            case .nicknameCheck: return "/auth/nickname-check"
            case .firebaseConfig: return "/firebase/config"
            case .socialLogin: return "/auth/social"
            case .socialRegister: return "/auth/social-register"
            case .deleteAccount: return "/auth/me"
            case .me: return "/auth/me"
            case .logout: return "/auth/logout"
            case .onboardingComplete: return "/auth/onboarding-complete"
        }
    }

    /// 최종 요청 URL 구성
    var url: URL {
        APIEnvironment.baseURL.appendingPathComponent(path)
    }
}

enum SocialLoginResult {
    /// 기존 가입 사용자로 인증이 완료된 상태입니다.
    case signedIn(TokenPair)
    /// 소셜 로그인은 성공했지만 추가 회원가입(닉네임 입력)이 필요한 상태입니다.
    case needsRegister(email: String?, providerUid: String)
}

// MARK: - Auth Service Protocol

/// ViewModel이 의존하는 Auth API 계약입니다.
///
/// 실제 네트워크 구현은 `AuthServiceImpl`이 담당하고,
/// 토큰 저장도 그 구현체가 맡습니다.
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
    /// - Throws:
    ///     인증 토큰 누락 / 네트워크 오류 / 서버 오류 / 인증 실패
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

    /// 닉네임 사용 가능 여부를 확인합니다.
    ///
    /// - Endpoint:
    ///     `POST /auth/nickname-check`
    ///
    /// - Parameters:
    ///     - nickname: 중복 확인할 닉네임
    ///
    /// - Returns:
    ///     사용 가능 여부 (`true` / `false`)
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 오류 / 검증 실패
    func checkNickname(_ nickname: String) async throws -> Bool

    /// 소셜 로그인(구글 등)을 처리합니다.
    ///
    /// - Endpoint:
    ///     `POST /auth/social`
    ///
    /// - Parameters:
    ///     - idToken: 소셜 제공자에서 발급된 ID 토큰
    ///     - provider: 소셜 제공자 식별자 (`google` 등)
    ///
    /// - Returns:
    ///     `SocialLoginResult` (`signedIn` 또는 `needsRegister`)
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 오류 / 인증 실패
    func socialLogin(idToken: String, provider: String) async throws -> SocialLoginResult

    /// 소셜 회원가입을 완료합니다.
    ///
    /// - Endpoint:
    ///     `POST /auth/social-register`
    ///
    /// - Parameters:
    ///     - provider: 소셜 제공자 식별자
    ///     - providerUid: 소셜 제공자 사용자 고유 ID
    ///     - nickname: 사용자 닉네임
    ///     - email: 사용자 이메일(옵션)
    ///
    /// - Returns:
    ///     `TokenPair`
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 오류 / 검증 실패
    func socialRegister(provider: String, providerUid: String, nickname: String, email: String?) async throws -> TokenPair

    /// 회원탈퇴 요청
    ///
    /// - Endpoint:
    ///     `DELETE /auth/me`
    func deleteAccount() async throws

    /// 내 정보 조회 요청
    ///
    /// - Endpoint:
    ///     `GET /auth/me`
    func fetchMe() async throws -> MeResponse

    /// 로그아웃 요청
    ///
    /// - Endpoint:
    ///     `POST /auth/logout`
    func logout() async throws

    /// 닉네임을 변경합니다.
    ///
    /// - Endpoint:
    ///     `POST /auth/nickname-update`
    ///
    /// - Parameters:
    ///     - nickname: 변경할 닉네임
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 오류 / 검증 실패
    func updateNickname(_ nickname: String) async throws

    /// 온보딩 완료 상태를 서버에 반영합니다.
    ///
    /// - Endpoint:
    ///     `POST /auth/onboarding-complete`
    func completeOnboarding() async throws -> OnboardingCompleteResponse
}

// MARK: - Auth Service Implementation

/// Auth API의 실제 네트워크 구현입니다.
///
/// 네트워크 호출과 토큰 저장만 담당하고,
/// 데이터 가공은 ViewModel/Entity 쪽에서 처리합니다.
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
        let requestBody = LoginRequest(
            email: email,
            password: password,
            deviceId: DeviceID.shared.value
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if http.statusCode != 200 {
            let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("[AuthService] login status:", http.statusCode)
            print("[AuthService] login body:", bodyText)
        }

        switch http.statusCode {
            case 200:
                let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
                TokenStore.shared.updateTokens(pair: decoded)
                return decoded

            case 403:
                if isDeletedAccountError(data: data) {
                    throw AuthError.accountDeleted
                }
                throw AuthError.server

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

    /// 닉네임 중복 검사 요청을 전송합니다.
    func checkNickname(_ nickname: String) async throws -> Bool {
        let url = AuthEndpoint.nicknameCheck.url
        let requestBody = NicknameCheckRequest(nickname: nickname)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.server
        }

        if http.statusCode != 200 {
            let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("[AuthService] nickname-check status:", http.statusCode)
            print("[AuthService] nickname-check body:", bodyText)
        }

        switch http.statusCode {
        case 200:
            let decoded = try JSONDecoder().decode(NicknameCheckResponse.self, from: data)
            return decoded.available

        case 409:
            return false

        case 422:
            throw AuthError.validation("닉네임 형식을 확인해주세요.")

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
    ///
    /// - Endpoint:
    ///     `POST /auth/refresh`
    ///
    /// - Throws:
    ///     refresh token 누락 / 네트워크 오류 / 서버 응답 오류 / 인증 실패
    @discardableResult
    func refresh() async throws -> TokenPair {

        guard let refreshToken = TokenStore.shared.refreshToken() else {
            throw URLError(.userAuthenticationRequired)
        }

        let url = AuthEndpoint.refresh.url

        let body = RefreshRequest(
            refreshToken: refreshToken,
            deviceId: DeviceID.shared.value,
            platform: "ios"
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.server
        }

        switch http.statusCode {
            case 200:
                let tokenPair = try JSONDecoder().decode(TokenPair.self, from: data)
                TokenStore.shared.updateTokens(pair: tokenPair)
                return tokenPair

            case 401:
                throw AuthError.invalidCredentials

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

    /// 소셜 로그인 요청을 전송합니다.
    ///
    /// - Endpoint:
    ///     `POST /auth/social`
    ///
    /// - Parameters:
    ///     - idToken: 소셜 제공자에서 발급된 ID 토큰
    ///     - provider: 소셜 제공자 식별자 (`google` 등)
    ///
    /// - Returns:
    ///     `SocialLoginResult`
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 응답 오류 / 인증 실패(`accountDeleted` 포함)
    func socialLogin(idToken: String, provider: String) async throws -> SocialLoginResult {

        let url = AuthEndpoint.socialLogin.url
        let body = SocialIdTokenLoginRequest(
            idToken: idToken,
            provider: provider,
            deviceId: DeviceID.shared.value
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.server
        }

        switch http.statusCode {

        case 200:
            let tokens = try JSONDecoder().decode(TokenPair.self, from: data)
            TokenStore.shared.updateTokens(pair: tokens)
            return .signedIn(tokens)

        case 202:
            let decoded = try JSONDecoder().decode(RegistrationNeededResponse.self, from: data)
            return .needsRegister(email: decoded.email, providerUid: decoded.providerUid)

        case 403:
            if isDeletedAccountError(data: data) {
                throw AuthError.accountDeleted
            }
            throw AuthError.server

        default:
            throw AuthError.server
        }
    }

    /// 소셜 회원가입 요청을 전송합니다.
    ///
    /// - Endpoint:
    ///     `POST /auth/social-register`
    ///
    /// - Parameters:
    ///     - provider: 소셜 제공자 식별자
    ///     - providerUid: 소셜 제공자 사용자 고유 ID
    ///     - nickname: 가입 시 사용할 닉네임
    ///     - email: 이메일(옵션)
    ///
    /// - Returns:
    ///     `TokenPair`
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 응답 오류 / 검증 실패
    func socialRegister(provider: String, providerUid: String, nickname: String, email: String?) async throws -> TokenPair {

        let url = AuthEndpoint.socialRegister.url
        let body = SocialRegisterRequest(
            provider: provider,
            providerUid: providerUid,
            nickname: nickname,
            email: email,
            deviceId: DeviceID.shared.value
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encodedBody = try JSONEncoder().encode(body)
        req.httpBody = encodedBody
        if let bodyText = String(data: encodedBody, encoding: .utf8) {
            print("[AuthService] social-register request body:", bodyText)
        } else {
            print("[AuthService] social-register request body: <non-utf8>")
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.server
        }

        if http.statusCode != 200 {
            let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("[AuthService] social-register status:", http.statusCode)
            print("[AuthService] social-register body:", bodyText)
        }

        switch http.statusCode {
            case 200:
                let tokens = try JSONDecoder().decode(TokenPair.self, from: data)
                TokenStore.shared.updateTokens(pair: tokens)
                return tokens

            case 409:
                throw AuthError.conflict("email")

            case 422:
                throw AuthError.validation("형식 오류")

            default:
                throw AuthError.server
        }
    }

    /// 회원탈퇴 요청을 전송합니다.
    ///
    /// - Endpoint:
    ///     `DELETE /auth/me`
    ///
    /// - Returns:
    ///     없음
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 응답 오류 / 인증 실패
    func deleteAccount() async throws {
        let url = AuthEndpoint.deleteAccount.url
        let request = try authorizedRequest(url: url, method: "DELETE")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.server
        }

        switch http.statusCode {
            case 204:
                return
            case 401:
                throw AuthError.invalidCredentials
            default:
                throw AuthError.server
        }
    }

    /// 내 정보 조회 요청을 전송합니다.
    ///
    /// - Endpoint:
    ///     `GET /auth/me`
    ///
    /// - Returns:
    ///     `MeResponse`
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 응답 오류 / 인증 실패
    func fetchMe() async throws -> MeResponse {
        let url = AuthEndpoint.me.url
        let request = try authorizedRequest(url: url, method: "GET")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.server
        }

        switch http.statusCode {
            case 200:
                if data.isEmpty {
                    return MeResponse(userId: nil, onboardingCompleted: nil)
                }
                return try JSONDecoder().decode(MeResponse.self, from: data)
            case 401:
                throw AuthError.invalidCredentials
            default:
                throw AuthError.server
        }
    }

    /// 로그아웃 요청을 전송합니다.
    ///
    /// - Endpoint:
    ///     `POST /auth/logout`
    ///
    /// - Returns:
    ///     없음
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 응답 오류 / 인증 실패
    func logout() async throws {
        guard let refreshToken = TokenStore.shared.refreshToken() else {
            throw URLError(.userAuthenticationRequired)
        }

        let url = AuthEndpoint.logout.url
        let body = RefreshRequest(
            refreshToken: refreshToken,
            deviceId: DeviceID.shared.value,
            platform: "ios"
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.server
        }

        switch http.statusCode {
            case 200:
                return
            case 401:
                throw AuthError.invalidCredentials
            default:
                throw AuthError.server
        }
    }

    /// Access Token이 포함된 인증 요청을 생성합니다.
    ///
    /// - Parameters:
    ///     - url: 요청 URL
    ///     - method: HTTP 메서드
    ///
    /// - Returns:
    ///     Authorization 헤더가 포함된 `URLRequest`
    ///
    /// - Throws:
    ///     Access Token이 없을 때 `URLError.userAuthenticationRequired`
    private func authorizedRequest(url: URL, method: String) throws -> URLRequest {
        guard let token = TokenStore.shared.accessToken() else {
            throw URLError(.userAuthenticationRequired)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// 닉네임 변경 요청을 전송합니다.
    ///
    /// - Endpoint:
    ///     `POST /auth/nickname-update`
    ///
    /// - Parameters:
    ///     - nickname: 변경할 닉네임
    ///
    /// - Returns:
    ///     없음
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 응답 오류 / 검증 실패
    func updateNickname(_ nickname: String) async throws {
        let url = APIEnvironment.baseURL.appendingPathComponent("/auth/nickname-update")
        let body = UpdateNicknameRequest(nickName: nickname)

        var request = try authorizedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoded = try JSONEncoder().encode(body)
        request.httpBody = encoded

        if let bodyText = String(data: encoded, encoding: .utf8) {
            print("[AuthService] nickname-update request body:", bodyText)
        } else {
            print("[AuthService] nickname-update request body: <non-utf8>")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.server
        }

        let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
        print("[AuthService] nickname-update status:", http.statusCode)
        print("[AuthService] nickname-update body:", bodyText)

        switch http.statusCode {
            case 200: return
            case 409: throw AuthError.conflict("nickname")
            case 422: throw AuthError.validation("형식 오류")
            default: throw AuthError.server
        }
    }

    /// 온보딩 완료 요청을 전송합니다.
    ///
    /// - Endpoint:
    ///     `POST /auth/onboarding-complete`
    ///
    /// - Returns:
    ///     `OnboardingCompleteResponse`
    ///
    /// - Note:
    ///     응답 바디가 비어도 완료로 간주해 `onboardingCompleted: true`로 보정합니다.
    ///
    /// - Throws:
    ///     네트워크 오류 / 서버 응답 오류 / 인증 실패
    func completeOnboarding() async throws -> OnboardingCompleteResponse {
        let url = AuthEndpoint.onboardingComplete.url
        let request = try authorizedRequest(url: url, method: "POST")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.server
        }

        switch http.statusCode {
            case 200:
                // 서버 응답 바디가 비어있거나 필드가 누락되어도 완료로 간주합니다.
                if data.isEmpty {
                    return OnboardingCompleteResponse(userId: nil, onboardingCompleted: true)
                }
                if let decoded = try? JSONDecoder().decode(OnboardingCompleteResponse.self, from: data) {
                    return decoded
                }
                return OnboardingCompleteResponse(userId: nil, onboardingCompleted: true)
            case 401:
                throw AuthError.invalidCredentials
            default:
                throw AuthError.server
        }
    }

    /// 서버 에러 본문에서 탈퇴 계정 여부를 판별합니다.
    ///
    /// - Parameters:
    ///     - data: 서버 응답 바디 데이터
    ///
    /// - Returns:
    ///     탈퇴 계정 에러 본문이면 `true`
    private func isDeletedAccountError(data: Data) -> Bool {
        let bodyText = String(data: data, encoding: .utf8)?.lowercased() ?? ""
        return bodyText.contains("account deleted")
    }
}
