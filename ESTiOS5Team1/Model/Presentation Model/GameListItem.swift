//
//  GameListItem.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation

/// 게임 목록 화면에서 사용되는 View 전용 모델입니다.
///
/// `GameEntity`를 기반으로 하여,
/// UI에서 바로 사용할 수 있도록 문자열 포맷 및 데이터 가공을 수행합니다.
///
/// - Important:
/// 이 타입은 화면에 표시하기 위한 데이터만을 담습니다.
/// 앱 내부 로직이나 네트워크 처리에는 사용하지 않습니다.

struct GameListItem: Identifiable, Hashable {

    /// 게임의 고유 식별자
    ///
    /// SwiftUI의 `List` / `ForEach`에서 식별자로 사용됩니다.
    let id: Int

    /// 화면에 표시될 게임 제목
    let title: String

    /// 게임 커버 이미지 URL
    ///
    /// 이미지가 없는 경우 `nil`이 될 수 있으며,
    /// UI에서는 placeholder 이미지로 대체할 수 있습니다.
    let coverURL: URL?

    /// 화면 표시용 평점 문자열
    ///
    /// 평점이 존재하는 경우 소수점 한 자리까지 포맷된 문자열을 사용하며,
    /// 평점 정보가 없는 경우 `"N/A"`로 표시됩니다.
    let ratingText: String

    /// 게임 장르 목록
    ///
    /// 여러 개의 장르가 존재할 수 있으며,
    /// UI에서는 `"Action · RPG"`와 같은 형태로 가공하여 표시할 수 있습니다.
    let genre: [String]

    /// 플랫폼 카테고리 목록입니다.
    ///
    /// IGDB에서 내려오는 다양한 플랫폼 이름을
    /// 앱에서 사용하는 `Platform` enum으로 매핑한 결과이며,
    /// 중복은 제거되어 저장됩니다.
    let platformCategories: [Platform]

    /// `GameEntity`를 기반으로 `GameListItem`을 생성합니다.
    ///
    /// Entity 데이터를 UI에서 쓰기 좋은 형태로 바꾸며,
    /// 평점 문자열 포맷(`ratingText`)과 같은 가공 로직이 포함됩니다.
    ///
    /// - Parameter entity: 앱 내부 도메인 모델인 `GameEntity`
    init(entity: GameEntity) {
        self.id = entity.id
        self.title = entity.title
        self.coverURL = entity.coverURL
        self.ratingText = entity.rating
            .map { String(format: "%.1f", $0 / 20.0) } ?? "N/A"
        self.genre = entity.genre
        self.platformCategories = Array(
            Set( entity.platforms.compactMap { Platform(igdbName: $0.name) })
        )
    }
}
