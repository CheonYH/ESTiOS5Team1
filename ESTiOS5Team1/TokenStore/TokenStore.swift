//
//  TokenStore.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation

/// Access / Refresh 토큰을 Keychain에 안전하게 보관하는 스토어
final class TokenStore {

    static let shared = TokenStore()
    private init() {}

    private enum Key {
        static let access = "accessToken"
        static let refresh = "refreshToken"
    }

    // MARK: - Save / Update

    func updateTokens(response: LoginResponse) {
        // 항상 access는 업데이트
        KeychainStore.shared.save(key: Key.access, value: response.accessToken)

        // refreshToken이 있을 때만 업데이트
        if let refresh = response.refreshToken {
            KeychainStore.shared.save(key: Key.refresh, value: refresh)
        }
    }

    func updateAccessToken(_ access: String) {
        KeychainStore.shared.save(key: Key.access, value: access)
    }

    func updateRefreshToken(_ refresh: String) {
        KeychainStore.shared.save(key: Key.refresh, value: refresh)
    }

    // MARK: - Load

    func accessToken() -> String? {
        KeychainStore.shared.read(key: Key.access)
    }

    func refreshToken() -> String? {
        KeychainStore.shared.read(key: Key.refresh)
    }

    // MARK: - Clear (로그아웃)

    func clear() {
        KeychainStore.shared.delete(key: Key.access)
        KeychainStore.shared.delete(key: Key.refresh)
    }
}

