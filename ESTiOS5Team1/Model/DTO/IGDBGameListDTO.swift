//
//  IGDBGameListDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation

/// IGDB API에서 게임 목록 조회 시 사용되는 DTO입니다.
///
/// `/v4/games` 엔드포인트의 응답 구조에 대응하며,
/// 네트워크 계층에서 전달받은 **원본 JSON 응답을 그대로 표현**합니다.
///
/// - Important:
/// 이 타입은 **가공되지 않은 API 응답 모델**입니다.
/// UI 표시용 포맷팅, Optional 처리, 문자열 변환 등은
/// 반드시 `GameEntity` 또는 ViewModel 단계에서 수행해야 합니다.
struct IGDBGameListDTO: Codable, Hashable, Identifiable {

    /// IGDB에서 부여한 게임의 고유 식별자
    ///
    /// 이후 Entity 및 ViewModel 단계에서도
    /// 동일한 식별자로 사용됩니다.
    let id: Int

    /// 게임의 공식 이름
    ///
    /// IGDB에 등록된 기본 타이틀 값입니다.
    let name: String

    /// 게임의 커버 이미지 정보
    ///
    /// IGDB는 실제 이미지 URL을 반환하지 않고
    /// `image_id`만 제공하므로,
    /// 클라이언트에서 URL을 조합해야 합니다.
    ///
    /// - Note:
    /// 커버 이미지가 등록되지 않은 게임도 많기 때문에 Optional입니다.
    let cover: IGDBImageDTO?

    /// IGDB 내부 알고리즘 기반 종합 평점 (0 ~ 100)
    ///
    /// - Note:
    /// 평점 정보가 없는 게임의 경우 `nil`이 반환됩니다.
    /// 앱 내부에서는 5점 만점 등으로 스케일링하여
    /// 표시하는 것이 일반적입니다.
    let rating: Double?

    /// 게임에 연결된 장르 목록
    ///
    /// 하나의 게임은 여러 개의 장르를 가질 수 있습니다.
    ///
    /// - Note:
    /// 장르 정보가 없는 경우 빈 배열이 아닌 `nil`로 응답됩니다.
    let genres: [GenreDTO]?

    /// 게임이 출시된 플랫폼 목록
    ///
    /// 각 플랫폼은 이름과 로고 정보를 포함할 수 있으며,
    /// 실제 UI에서 사용할 플랫폼 아이콘/텍스트는
    /// `GameEntity` 단계에서 정규화합니다.
    ///
    /// - Important:
    /// IGDB의 플랫폼 명칭은 매우 다양하므로
    /// 이 DTO 값은 그대로 사용하지 않고
    /// `Platform` enum 등을 통해 매핑하는 것이 권장됩니다.
    let platforms: [IGDBPlatformDTO]?

    let releaseDates: [IGDBReleaseDateDTO]?

    let aggregatedRating: Double?

    let summary: String?

    let storyline: String?

    let ageRatings: [IGDBAgeRatingDTO]?
}

enum CodingKeys: String, CodingKey {

    case ageRatings = "age_ratings"
    case releaseDates = "release_dates"
    case aggregatedRating = "aggregated_rating"

}

/// IGDB API에서 제공하는 장르 정보를 표현하는 DTO입니다.
///
/// 게임 하나에 여러 개의 장르가 연결될 수 있으며,
/// `IGDBGameListDTO.genres`를 통해 참조됩니다.
struct GenreDTO: Codable, Hashable, Identifiable {

    /// IGDB에서 부여한 장르 고유 식별자
    let id: Int

    /// 장르의 표시 이름 (예: Action, RPG, Adventure)
    let name: String
}
