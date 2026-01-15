//
//  AuthDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation

// MARK: - Login Request DTO
/// 로그인 요청에 사용되는 모델입니다.
/// 사용자가 로그인 화면에서 입력한 이메일과 비밀번호를 서버로 전달할 때 사용합니다.
///
/// 서버 요청 예:
/// ```json
/// {
///   "email": "test@example.com",
///   "password": "1234"
/// }
/// ```
///
/// 이 요청은 Vapor 서버의 `/auth/login` 엔드포인트에서 처리됩니다.
struct LoginRequest: Codable, Hashable {
    let email: String
    let password: String
}


// MARK: - Login Response / Token Pair DTO
/// 로그인 성공 시 서버에서 반환하는 토큰 쌍(Token Pair) 모델입니다.
///
/// 서버 응답 예:
/// ```json
/// {
///   "access": "<JWT Access Token>",
///   "refresh": "<Refresh Token>"
/// }
/// ```
///
/// - accessToken:
///     이 토큰은 보호된 API 요청에 사용되며 Authorization 헤더에 포함됩니다.
///     예: `Authorization: Bearer <accessToken>`
///
/// - refreshToken:
///     access token 만료 시 새로운 access token을 발급받기 위해 사용됩니다.
///
/// - Important:
///     refreshToken은 **절대 UserDefaults에 저장하면 안 되며** Keychain에 저장해야 합니다.
///
/// - Note:
///     refreshToken이 `nil`일 수도 있습니다.
///     예: refresh API는 refresh token을 재발급하지 않는 서버 정책일 수 있습니다.
struct LoginResponse: Codable, Hashable {
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access"
        case refreshToken = "refresh"
    }
}


// MARK: - Refresh Request DTO
/// refresh token을 이용하여 새로운 access token을 발급받는 요청 모델입니다.
///
/// 서버 요청 예:
/// ```json
/// {
///   "refreshToken": "<Refresh Token>"
/// }
/// ```
///
/// - Important:
///     refresh token은 Keychain에서 가져와야 하며,
///     refresh 실패 시 사용자의 인증 상태를 signedOut으로 변경해야 합니다.
///
/// 이 요청은 `/auth/refresh` 엔드포인트에서 처리됩니다.
struct RefreshRequest: Codable {
    let refreshToken: String
}


// MARK: - TokenPair Alias
/// 서버에서 `access + refresh` 토큰을 함께 반환하는 경우가 많기 때문에
/// 서로 다른 API(`login`, `refresh`)의 응답을 동일한 모델로 처리할 수 있습니다.
///
/// - Example:
///     refresh API 응답도 TokenPair로 처리 가능
///
/// ```swift
/// let tokens: TokenPair = try await authService.refresh()
/// ```
typealias TokenPair = LoginResponse

struct RegisterRequest: Codable, Hashable {
    let email: String
    let password: String
    let nickname: String
}

struct RegisterResponse: Codable, Hashable {
    let success: Bool
}
