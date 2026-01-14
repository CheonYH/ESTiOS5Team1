//
//  KeychainStore.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation
import Security

final class KeychainStore {
    static let shared = KeychainStore()

    private init() {

    }

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

    func update(key: String, value: String) {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        SecItemUpdate(query as  CFDictionary, attributes as CFDictionary)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        
        SecItemDelete(query as CFDictionary)
    }

    func read(key: String) -> String? {
        let query: [String : Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        guard let data = item as? Data else {
            return nil
        }

        return String(decoding: data, as: UTF8.self)
    }

}
