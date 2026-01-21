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

    let stores: [StoreItem]        // UI friendly
    let officialWebsite: URL?
    let trailers: [URL]
    let developers: [String]
    let publishers: [String]

    /// 화면 표시용 평점 문자열 ("8.5" / "N/A")
    let ratingText: String
}

struct StoreItem: Hashable, Identifiable {
    let id = UUID()
    let name: String
    let icon: String     // SF Symbol or Asset name
    let url: URL
}

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

    init(detail: GameDetailEntity) {
        self.id = detail.id
        self.title = detail.title
        self.coverURL = detail.coverURL

        self.ratingText = detail.rating
            .map { String(format: "%.1f", $0 / 20.0) } ?? "N/A"

        self.metaScore = detail.metaScore
            .map { String(format: "%.0f", $0) } ?? "N/A"

        self.releaseYear = detail.releaseYear
            .map { "\($0)" } ?? "–"

        self.summary = detail.summary
        self.description = detail.storyline

        self.genre = detail.genres

        self.platforms = Array(Set(
            detail.platforms.compactMap { Platform(igdbName: $0.name) }
        ))

        // 🔹 Store UI Model 변환
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
