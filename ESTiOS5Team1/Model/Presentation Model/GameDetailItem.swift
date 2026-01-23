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

    /// 게임 고유 ID입니다.
    let id: Int
    /// 게임 제목입니다.
    let title: String
    /// 커버 이미지 URL입니다. (없을 수 있음)
    let coverURL: URL?

    /// 메타 점수 (0~100)
    let metaScore: String

    /// 출시 연도 표시 문자열입니다.
    let releaseYear: String
    /// 간단 요약 텍스트입니다.
    let summary: String?
    /// 상세 설명(스토리라인) 텍스트입니다.
    let description: String?
    /// 장르 목록입니다.
    let genre: [String]
    /// UI에서 사용하는 플랫폼 카테고리입니다.
    let platforms: [Platform]

    /// 스토어 링크 UI 모델 목록입니다.
    let stores: [StoreItem]        // UI friendly
    /// 공식 웹사이트 URL입니다.
    let officialWebsite: URL?
    /// 트레일러 URL 목록입니다.
    let trailers: [URL]
    /// 개발사 이름 목록입니다.
    let developers: [String]
    /// 배급사 이름 목록입니다.
    let publishers: [String]

    /// 화면 표시용 평점 문자열 ("8.5" / "N/A")
    let ratingText: String
}

/// 스토어 표시용 UI 모델입니다.
struct StoreItem: Hashable, Identifiable {
    /// 로컬 식별자입니다. (UI 리스트용)
    let id = UUID()
    /// 스토어 이름입니다.
    let name: String
    /// 스토어 아이콘 이름입니다. (SF Symbol 또는 Asset)
    let icon: String     // SF Symbol or Asset name
    /// 스토어 이동 URL입니다.
    let url: URL
}

/// 스토어 enum을 표시용 문자열로 변환합니다.
private func storeName(for store: Store) -> String {
    switch store {
    case .steam: return "Steam"
    case .playstation: return "PlayStation"
    case .xbox: return "Xbox"
    case .epic: return "Epic Games"
    case .nintendo: return "Nintendo"
    case .gog: return "GOG"
    case .other(let name): return name
    }
}

/// 스토어 enum을 아이콘 이름으로 변환합니다.
private func storeIcon(for store: Store) -> String {
    switch store {
    case .steam: return "steam.icon"
    case .playstation: return "playstation.icon"
    case .xbox: return "xbox.icon"
    case .epic: return "epic.icon"
    case .nintendo: return "nintendo.icon"
    case .gog: return "gog.icon"
    case .other: return "globe"
    }
}

extension GameDetailItem {

    /// `GameDetailEntity`를 화면 표시용 모델로 변환합니다.
    init(detail: GameDetailEntity, review: GameReviewEntity) {
        self.id = detail.id
        self.title = detail.title
        self.coverURL = detail.coverURL

        // 통계 기반 평균 평점을 표시합니다.
        if let averageRating = review.stats?.averageRating {
            self.ratingText = String(format: "%.1f/5", averageRating)
        } else {
            self.ratingText = "N/A"
        }

        self.metaScore = detail.metaScore
            .map { String(format: "%.1f", $0 / 20.0) } ?? "N/A"

        self.releaseYear = detail.releaseYear
            .map { "\($0)" } ?? "–"

        self.summary = detail.summary
        self.description = detail.storyline

        self.genre = detail.genres

        self.platforms = Array(Set(
            detail.platforms.compactMap { Platform(igdbName: $0.name) }
        ))

        // Store UI Model 변환
        self.stores = detail.storeLinks.map { link in
            StoreItem(
                name: storeName(for: link.store),
                icon: storeIcon(for: link.store),
                url: link.url
            )
        }

        self.officialWebsite = detail.officialWebsite
        self.trailers = detail.trailerUrls

        self.developers = detail.developers
        self.publishers = detail.publishers
    }
}
