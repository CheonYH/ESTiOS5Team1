//
//  GameDetailItem.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation

/// 게임 상세 화면에서 사용하는 View 전용 모델입니다.
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

    }
}
