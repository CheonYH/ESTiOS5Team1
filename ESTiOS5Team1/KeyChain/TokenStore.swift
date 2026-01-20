//
//  TokenStore.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation

/// TokenStore는 인증 과정에서 발급된 Access / Refresh 토큰을
/// Keychain을 통해 안전하게 저장하고 관리하는 컴포넌트입니다.
///
/// - Purpose:
///     클라이언트에서 로그인 상태 유지 및 자동 로그인에 사용됩니다.
///
/// - Important:
///     TokenStore는 토큰을 저장하고 반환할 뿐이며,
///     로그인/로그아웃/refresh 처리 로직은 AuthService에서 담당합니다.
///
/// - Note:
///     Keychain에 저장하기 때문에 앱 재시작, 백그라운드 전환, 재부팅 이후에도
///     로그인 상태를 유지할 수 있습니다.
final class TokenStore {

    /// Singleton 인스턴스
    static let shared = TokenStore()

    private init() {}

    // MARK: - Key Constants

    /// Keychain에 저장할 key 명을 정적으로 정의합니다.
    ///
    /// Key를 문자열 하드코딩하지 않도록 enum으로 분리했습니다.
    private enum Key {
        static let access = "accessToken"
        static let refresh = "refreshToken"
    }

    // MARK: - Save / Update Tokens

    /// 로그인/refresh API 응답에서 받은 토큰을 저장합니다.
    ///
    /// - Parameter response: 서버에서 받은 LoginResponse(TokenPair)
    ///
    /// - Important:
    ///     refreshToken이 `nil`일 수 있으므로 조건적으로 저장합니다.
    ///
    /// - Example:
    /// ```swift
    /// let tokens = try await authService.refresh()
    /// TokenStore.shared.updateTokens(response: tokens)
    /// ```
    func updateTokens(pair: LoginResponse) {
        updateAccessToken(pair.accessToken)

        if let refresh = pair.refreshToken {
            updateRefreshToken(refresh)
        }
    }


    /// Access Token만 갱신할 때 사용합니다.
    ///
    /// 예: Refresh 요청 후 access만 rotation될 경우
    func updateAccessToken(_ access: String) {
        KeychainStore.shared.save(key: Key.access, value: access)
    }

    /// Refresh Token만 갱신할 때 사용합니다.
    func updateRefreshToken(_ refresh: String) {
        KeychainStore.shared.save(key: Key.refresh, value: refresh)
    }

    // MARK: - Load Tokens

    /// 저장된 Access Token을 반환합니다.
    ///
    /// - Returns: 저장된 access token 또는 nil (로그아웃 상태)
    func accessToken() -> String? {
        KeychainStore.shared.read(key: Key.access)
    }

    /// 저장된 Refresh Token을 반환합니다.
    ///
    /// - Returns: 저장된 refresh token 또는 nil
    ///
    /// - Important:
    ///     refresh token이 nil이면 자동 로그인(Session Restore)이 불가능합니다.
    func refreshToken() -> String? {
        KeychainStore.shared.read(key: Key.refresh)
    }

    // MARK: - Logout / Session Clear

    /// 토큰을 제거하여 로그인 세션을 완전히 종료합니다.
    ///
    /// - Note:
    ///     이 작업은 클라이언트 측 세션만 종료하며,
    ///     서버 측 refresh token revoke 정책은 별도 구현이 필요할 수 있습니다.
    func clear() {
        KeychainStore.shared.delete(key: Key.access)
        KeychainStore.shared.delete(key: Key.refresh)
    }
}
