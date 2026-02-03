//
//  GenrePreferenceStore.swift
//  ESTiOS5Team1
//
//  Created by cheon on 2/3/26.
//

import Foundation

/// 선호 장르 저장/로드를 한 곳에서 관리합니다.
struct GenrePreferenceStore {

    /// 선택된 장르를 IGDB ID 기준으로 저장합니다.
    ///
    /// - Parameters:
    ///   - genres: 화면에서 선택된 장르 집합
    static func save(_ genres: Set<GenreFilterType>) {
        let ids = genres.compactMap(\.igdbGenreId).sorted()
        PreferenceStore.preferredGenreIds = ids
        PreferenceStore.preferredGenreId = ids.first
    }

    /// 저장된 IGDB ID를 화면 장르 타입으로 변환해 반환합니다.
    ///
    /// - Returns:
    ///   화면에서 바로 사용할 수 있는 `GenreFilterType` 집합
    static func load() -> Set<GenreFilterType> {
        let idSet = Set(PreferenceStore.preferredGenreIds)
        guard !idSet.isEmpty else { return [] }

        return Set(
            GenreFilterType.allCases.filter { genre in
                guard let id = genre.igdbGenreId else { return false }
                return idSet.contains(id)
            }
        )
    }

    /// 선호 장르 변경 알림을 발행합니다.
    static func notifyDidChange() {
        NotificationCenter.default.post(name: .preferredGenresDidChange, object: nil)
    }
}
