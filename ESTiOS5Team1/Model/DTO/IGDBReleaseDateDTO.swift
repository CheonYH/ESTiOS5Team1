//
//  IGDBReleaseDateDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation

/// IGDB의 출시일 정보를 표현하는 DTO입니다.
///
/// `year`는 연도만 간단히 표시할 때 사용되고,
/// `date`는 Unix timestamp(초)입니다.
struct IGDBReleaseDateDTO: Codable, Hashable {
    /// IGDB release_date 고유 ID
    let id: Int
    /// 출시 연도 (없을 수 있음)
    let year: Int?
    /// 출시 날짜 타임스탬프 (초 단위)
    let date: Int?
}
