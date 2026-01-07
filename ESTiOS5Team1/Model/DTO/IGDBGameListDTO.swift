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
/// 네트워크 계층에서 받은 원본 데이터를 표현합니다.
///
/// - Important:
/// 이 타입은 **API 응답 구조를 그대로 반영**하며,
/// 화면 표시를 위한 가공은 Entity / ViewModel 단계에서 수행합니다.
struct IGDBGameListDTO: Codable, Hashable, Identifiable {

    /// IGDB에서 부여한 게임의 고유 식별자
    let id: Int

    /// 게임의 공식 이름
    let name: String

    /// 게임의 커버 이미지 정보
    ///
    /// - Note:
    /// 커버 이미지가 등록되지 않은 게임도 많기 때문에 Optional입니다.
    let cover: IGDBImageDTO?

    /// IGDB 내부 알고리즘 기반 종합 점수 (0 ~ 100)
    ///
    /// - Note:
    /// 평점 데이터가 없는 게임의 경우 `nil`이 반환됩니다.
    /// UI에서는 "N/A" 등의 값으로 처리하는 것이 일반적입니다.
    let rating: Double?

    /// 게임에 연결된 장르 목록
    ///
    /// - Note:
    /// 장르 정보가 없는 게임도 존재하며,
    /// 이 경우 빈 배열이 아닌 `nil`로 응답됩니다.
    let genres: [GenreDTO]?
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
