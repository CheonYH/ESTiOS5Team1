//
//  IGDBAgeRatingDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/20/26.
//

import Foundation

/// IGDB에서 제공하는 연령 등급 정보를 표현하는 DTO입니다.
///
/// `/v4/games` 엔드포인트에서 `age_ratings.{id,category,rating}`
/// 필드를 요청했을 때의 응답 구조에 대응합니다.
///
/// - Important:
/// 이 타입은 raw API 응답 모델이며
/// 등급 라벨/연령 변환은 `AgeRatingEntity`에서 수행합니다.
struct IGDBAgeRatingDTO: Codable, Hashable, Identifiable {

    /// 연령 등급의 고유 ID
    let id: Int

    /// 등급 기관 카테고리 (ESRB, PEGI, GRAC 등)
    ///
    /// - 1: ESRB (북미)
    /// - 2: PEGI (유럽)
    /// - 5: GRAC (한국)
    let category: Int

    /// 해당 기관에서 정의한 등급 코드
    ///
    /// 예: ESRB Teen → 4, PEGI 16 → 10 등
    let rating: Int
}

