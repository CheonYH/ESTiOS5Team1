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
    /// 로그인 이메일입니다.
    let email: String
    /// 로그인 비밀번호입니다.
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
///     refreshToken은 보안상 Keychain에 저장하는 쪽으로 설계되어 있습니다.
///
/// - Note:
///     refreshToken이 `nil`일 수도 있습니다.
///     예: refresh API는 refresh token을 재발급하지 않는 서버 정책일 수 있습니다.
struct LoginResponse: Codable, Hashable {
    /// Access 토큰입니다.
    let accessToken: String
    /// Refresh 토큰입니다. (없을 수 있음)
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access"
        case refreshToken = "refresh"
    }
}

struct LogoutRequest: Codable {
    /// 로그아웃 대상 refresh 토큰입니다.
    let refreshToken: String
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
///     refresh 실패 시 앱 상태를 signedOut으로 전환하는 흐름을 사용합니다.
///
/// 이 요청은 `/auth/refresh` 엔드포인트에서 처리됩니다.
struct RefreshRequest: Codable {
    /// Refresh 토큰입니다.
    let refreshToken: String
    /// 기기 식별자입니다. (옵션)
    let deviceId: String?
    /// 플랫폼 정보입니다. (옵션)
    let platform: String?
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

// MARK: - Register Request DTO
/// 회원가입 요청에 사용되는 모델입니다.
///
/// 서버 요청 예:
/// ```json
/// {
///   "email": "test@example.com",
///   "password": "1234!abcd",
///   "nickname": "game_fan"
/// }
/// ```
///
/// - Note:
///     비밀번호 정책은 클라이언트/서버에서 모두 검증되어야 합니다.
struct RegisterRequest: Codable, Hashable {
    /// 회원가입 이메일입니다.
    let email: String
    /// 회원가입 비밀번호입니다.
    let password: String
    /// 닉네임입니다.
    let nickname: String
}

// MARK: - Register Response DTO
/// 회원가입 응답 모델입니다.
///
/// - success:
///     요청 처리 성공 여부
/// - message:
///     사용자에게 표시할 안내 메시지(검증 실패 사유 포함 가능)
struct RegisterResponse: Codable, Hashable {
    /// 성공 여부입니다.
    let success: Bool
    /// 안내 메시지입니다.
    let message: String
}

// MARK: - Social Login/Register DTO

/// 소셜 로그인 요청에 사용하는 모델입니다.
///
/// - Note:
/// 서버는 idToken을 검증한 뒤, 기존 계정이면 토큰을 반환하거나
/// 신규 사용자라면 가입이 필요하다는 응답을 반환합니다.
struct SocialIdTokenLoginRequest: Codable {
    /// 소셜 로그인 ID 토큰입니다.
    let idToken: String
    /// 소셜 제공자 이름입니다.
    let provider: String
}

/// 소셜 회원가입 요청에 사용하는 모델입니다.
///
/// - Important:
/// providerUid는 소셜 로그인 결과에서 받은 고유 식별자를 전달하는 용도입니다.
struct SocialRegisterRequest: Codable {
    /// 소셜 제공자 이름입니다.
    let provider: String
    /// 소셜 제공자 UID입니다.
    let providerUid: String
    /// 닉네임입니다.
    let nickname: String
    /// 이메일입니다. (없을 수 있음)
    let email: String?
}

/// 소셜 로그인 후 추가 가입이 필요한 경우의 서버 응답입니다.
struct RegistrationNeededResponse: Codable {
    /// 소셜 계정 이메일입니다. (없을 수 있음)
    let email: String?
    /// 소셜 제공자 UID입니다.
    let providerUid: String
}

// MARK: - Nickname Check DTO

/// 닉네임 중복 확인 요청 모델입니다.
struct NicknameCheckRequest: Codable {
    /// 중복 확인할 닉네임입니다.
    let nickname: String
}

/// 닉네임 중복 확인 응답 모델입니다.
struct NicknameCheckResponse: Decodable {
    /// 사용 가능 여부입니다.
    let available: Bool
}
