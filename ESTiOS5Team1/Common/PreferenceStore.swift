//
//  PreferenceStore.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/29/26.
//

import Foundation

/// UserDefaults 기반 선호 설정 저장소
struct PreferenceStore {
    /// 단일 선호 장르 저장 키
    private static let preferredGenreIdKey = "preferred_genre_id"
    /// 복수 선호 장르 저장 키
    private static let preferredGenreIdsKey = "preferred_genre_ids"

    /// 선호 장르 단일 ID (없으면 nil)
    static var preferredGenreId: Int? {
        get {
            let value = UserDefaults.standard.integer(forKey: preferredGenreIdKey)
            return value == 0 ? nil : value
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: preferredGenreIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: preferredGenreIdKey)
            }
        }
    }

    /// 선호 장르 복수 ID 목록 (없으면 빈 배열)
    static var preferredGenreIds: [Int] {
        get {
            UserDefaults.standard.array(forKey: preferredGenreIdsKey) as? [Int] ?? []
        }
        set {
            if newValue.isEmpty {
                UserDefaults.standard.removeObject(forKey: preferredGenreIdsKey)
            } else {
                UserDefaults.standard.set(newValue, forKey: preferredGenreIdsKey)
            }
        }
    }
}
