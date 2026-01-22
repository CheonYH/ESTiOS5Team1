//
//  KeychainStore.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation
import Security

/// KeychainStore는 민감한 데이터를 iOS Keychain에 안전하게 저장하기 위한 저장소입니다.
/// AccessToken / RefreshToken 같은 인증 정보 저장에 사용됩니다.
///
/// - Important:
///     refreshToken과 accessToken은 절대 `UserDefaults`에 저장하면 안 되며
///     반드시 Keychain을 사용해야 합니다.
///
/// - Note:
///     Keychain은 앱이 백그라운드, 재부팅, 앱 재시작 이후에도 데이터를 유지합니다.
///     로그인 유지(세션 유지)에 적합한 저장소입니다.
///
/// - Security:
///     데이터를 복호화 없이 그대로 저장하지 않으려면 추가적인 암호화 레이어를 적용할 수도 있습니다.
///     여기서는 iOS Keychain의 보안을 그대로 활용하는 기본 패턴을 사용합니다.
final class KeychainStore {

    static let shared = KeychainStore()

    private init() {}
}

// MARK: - Save Value
extension KeychainStore {

    /// Keychain에 데이터를 저장합니다.
    ///
    /// - If key가 이미 존재하면 업데이트(update)로 처리됩니다.
    ///
    /// - Parameters:
    ///   - key: 저장할 데이터의 식별자
    ///   - value: 저장할 값 (텍스트 기반)
    ///
    /// - Important:
    ///     `kSecAttrAccessibleAfterFirstUnlock` 옵션을 사용하여
    ///     재부팅 이후 첫 언락 이후 접근 가능하도록 설정했습니다.
    func save(key: String, value: String) {
        let data = Data(value.utf8)

        if read(key: key) != nil {
            update(key: key, value: value)
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemAdd(query as CFDictionary, nil)
    }
}

// MARK: - Update Value
extension KeychainStore {

    /// Keychain 값을 업데이트합니다.
    ///
    /// - Parameters:
    ///   - key: 저장된 항목의 key
    ///   - value: 새로운 값
    func update(key: String, value: String) {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    }
}

// MARK: - Delete Value
extension KeychainStore {

    /// Keychain에서 값을 삭제합니다.
    ///
    /// - Parameter key: 삭제할 항목의 key
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Read Value
extension KeychainStore {

    /// Keychain에서 값을 읽습니다.
    ///
    /// - Parameter key: 조회할 key
    ///
    /// - Returns: 저장된 문자열 또는 nil
    ///
    /// - Note:
    ///     값이 없거나 접근 실패 시 nil을 반환합니다.
    func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }
}
