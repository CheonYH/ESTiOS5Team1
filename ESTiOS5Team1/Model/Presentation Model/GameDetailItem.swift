//
//  GameDetailItem.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation

/// 게임 상세 화면에서 사용되는 View 전용 모델입니다.
///
/// `GameDetailEntity`를 기반으로 UI에서 바로 사용할 수 있는
/// 문자열 포맷 및 표시 데이터를 제공합니다.
///
/// - Important:
/// 이 타입은 화면 표시(View Layer)에 집중하며
/// 네트워크/비즈니스 로직은 담당하지 않습니다.
struct GameDetailItem: Identifiable, Hashable {

    let id: Int
    let title: String
    let coverURL: URL?

    /// 메타 점수 (0~100)
    let metaScore: String

    let releaseYear: String
    let summary: String?
    let description: String?
    let genre: [String]
    let platforms: [Platform]

    /// 화면 표시용 평점 문자열 ("8.5" / "N/A")
    let ratingText: String

    /// 한국 GRAC 기준 연령 등급
    ///
    /// - Example:
    ///     `.fifteen`, `.nineteen`
    let gracAge: GracAge

    /// 화면 표시용 연령 등급 라벨
    ///
    /// - Example:
    ///     "15세 이용가", "청소년 이용불가"
    let ageLabel: String
}

extension GameDetailItem {

    init(detail: GameDetailEntity) {

        self.id = detail.id
        self.title = detail.title
        self.coverURL = detail.coverURL

        // IGDB 평점 → 5점 만점 변환
        self.ratingText = detail.rating
            .map { String(format: "%.1f", $0 / 20.0) } ?? "N/A"

        // 메타 점수 (0~100)
        self.metaScore = detail.metaScore
            .map { String(format: "%.0f", $0) } ?? "N/A"

        // 출시년도
        self.releaseYear = detail.releaseYear
            .map { "\($0)" } ?? "–"

        self.summary = detail.summary
        self.description = detail.storyline

        self.genre = detail.genres

        self.platforms = Array(
            Set(detail.platforms.compactMap { Platform(igdbName: $0.name) })
        )

        // MARK: - 연령 등급 변환
        //
        // Domain Layer(`AgeRatingEntity`)에서 받은 GRAC 변환 결과를
        // 화면 표시용 데이터로 변환합니다.

        let grac = detail.ageRating?.gracAge ?? .all
        self.gracAge = grac

        switch grac {
        case .all:
            self.ageLabel = "전체 이용가"
        case .twelve:
            self.ageLabel = "12세 이용가"
        case .fifteen:
            self.ageLabel = "15세 이용가"
        case .nineteen:
            self.ageLabel = "청소년 이용불가"
        }
    }
}
