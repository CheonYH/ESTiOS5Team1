//
//  PreferenceStore.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/29/26.
//

import Foundation

/// UserDefaults 기반 선호 설정 저장소입니다.
///
/// - Note:
///     온보딩/프로필 화면에서 선택한 선호 장르를 로컬에 보관할 때 사용합니다.
struct PreferenceStore {
    /// 단일 선호 장르 저장 키
    private static let preferredGenreIdKey = "preferred_genre_id"
    /// 복수 선호 장르 저장 키
    private static let preferredGenreIdsKey = "preferred_genre_ids"

    /// 선호 장르 단일 ID입니다.
    ///
    /// - Returns:
    ///   저장값이 없으면 `nil`
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

    /// 선호 장르 복수 ID 목록입니다.
    ///
    /// - Returns:
    ///   저장값이 없으면 빈 배열
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
