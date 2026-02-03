//
//  GameDetailEntity.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation

/// 스토어 분류를 나타내는 타입입니다.
enum Store: Hashable {
    case steam
    case playstation
    case xbox
    case epic
    case nintendo
    case gog
    /// 기타 스토어입니다. (표시용 이름 포함)
    case other(String)
}

/// 스토어 링크 정보 모델입니다.
struct StoreLink: Hashable {
    /// 스토어 종류입니다.
    let store: Store
    /// 이동 URL입니다.
    let url: URL
}

/// 게임 상세 화면에 필요한 필드를 모은 엔티티입니다.
struct GameDetailEntity {
    /// 게임 고유 ID입니다.
    let id: Int
    /// 게임 제목입니다.
    let title: String
    /// 커버 이미지 URL입니다. (없을 수 있음)
    let coverURL: URL?
    /// 요약 텍스트입니다.
    let summary: String?
    /// 스토리라인 텍스트입니다.
    let storyline: String?
    /// IGDB 집계 메타 점수입니다. (0~100)
    let metaScore: Double?
    /// 출시 연도입니다. (없을 수 있음)
    let releaseYear: Int?
    /// 장르 목록입니다.
    let genres: [String]
    /// 지원 플랫폼 목록입니다.
    let platforms: [GamePlatform]
    /// 리뷰 기반 평점입니다. (0~5 범위)
    let rating: Double?

    /// 스토어 링크 목록입니다.
    let storeLinks: [StoreLink]
    /// 공식 웹사이트 URL입니다.
    let officialWebsite: URL?
    /// 트레일러 URL 목록입니다.
    let trailerUrls: [URL]
    /// 개발사 목록입니다.
    let developers: [String]
    /// 배급사 목록입니다.
    let publishers: [String]
}

extension GameDetailEntity {
    /// IGDB DTO와 리뷰 통계를 기반으로 상세 엔티티를 생성합니다.
    init(gameListDTO: IGDBGameListDTO, reviewDTO: ReviewStatsResponse) {
        self.id = gameListDTO.id
        self.title = gameListDTO.name

        self.coverURL = Self.makeCoverURL(from: gameListDTO)

        self.summary = gameListDTO.summary
        self.storyline = gameListDTO.storyline
        // aggregated_rating가 없으면 rating을 보조 값으로 사용합니다.
        self.metaScore = gameListDTO.aggregatedRating ?? gameListDTO.rating

        self.releaseYear = Self.latestReleaseYear(from: gameListDTO)

        self.genres = gameListDTO.genres?.map { $0.name } ?? []
        self.platforms = gameListDTO.platforms?.map { GamePlatform(name: $0.name) } ?? []
        self.rating = reviewDTO.averageRating

        self.officialWebsite = Self.officialWebsite(from: gameListDTO)

        // store links
        self.storeLinks = Self.storeLinks(from: gameListDTO)

        // 트레일러 (Youtube ID)
        self.trailerUrls = Self.trailerURLs(from: gameListDTO)

        // 개발사
        self.developers = Self.companyNames(from: gameListDTO, matching: { $0.developer == true })

        // 배급사 / 유통사
        self.publishers = Self.companyNames(from: gameListDTO, matching: { $0.publisher == true })
    }
}

private extension GameDetailEntity {
    /// 커버 이미지 URL을 생성합니다.
    static func makeCoverURL(from dto: IGDBGameListDTO) -> URL? {
        guard let imageID = dto.cover?.imageID else { return nil }
        // 상세 화면은 큰 사이즈 사용
        return makeIGDBImageURL(imageID: imageID, size: .coverBig)
    }

    /// 최신 출시 연도를 추출합니다.
    static func latestReleaseYear(from dto: IGDBGameListDTO) -> Int? {
        dto.releaseDates?.compactMap { $0.year }.max()
    }

    /// 공식 웹사이트 URL을 추출합니다.
    static func officialWebsite(from dto: IGDBGameListDTO) -> URL? {
        let official = dto.websites?
            .first(where: { $0.category == 1 })
            .flatMap { $0.url }
            .flatMap { URL(string: $0) }
        if official != nil {
            return official
        }

        let candidates = dto.websites?
            .compactMap { $0.url }
            .compactMap { URL(string: $0) }
            ?? []

        let excludedHosts = [
            "wikipedia.org",
            "fandom.com",
            "twitch.tv",
            "youtube.com",
            "youtu.be",
            "x.com",
            "twitter.com",
            "facebook.com",
            "instagram.com",
            "reddit.com",
            "discord.gg",
            "steam",
            "playstation",
            "xbox",
            "nintendo",
            "epicgames",
            "gog.com"
        ]

        return candidates.first { url in
            let host = (url.host ?? "").lowercased()
            return excludedHosts.allSatisfy { !host.contains($0) }
        }
    }

    /// 스토어 링크 목록을 추출합니다.
    static func storeLinks(from dto: IGDBGameListDTO) -> [StoreLink] {
        dto.websites?
            .compactMap { site in
                guard let urlString = site.url,
                      let url = URL(string: urlString) else { return nil }
                let store = site.category.map { Self.store(fromCategory: $0) } ?? Self.store(fromHost: url.host)
                return StoreLink(store: store, url: url)
            } ?? []
    }

    /// 웹사이트 카테고리 값을 스토어 타입으로 변환합니다.
    nonisolated static func store(fromCategory category: Int) -> Store {
        switch category {
        case 5:  return .steam
        case 10: return .epic
        case 13: return .nintendo
        case 14: return .xbox
        case 15: return .playstation
        case 6, 11: return .gog
        default: return .other("unknown")
        }
    }

    /// 웹사이트 호스트 문자열을 스토어 타입으로 추론합니다.
    nonisolated static func store(fromHost host: String?) -> Store {
        let lowercasedHost = host?.lowercased() ?? ""
        switch true {
        case lowercasedHost.contains("steampowered"):
            return .steam
        case lowercasedHost.contains("playstation"):
            return .playstation
        case lowercasedHost.contains("xbox"):
            return .xbox
        case lowercasedHost.contains("nintendo"):
            return .nintendo
        case lowercasedHost.contains("epicgames"):
            return .epic
        case lowercasedHost.contains("gog"):
            return .gog
        default:
            return .other("unknown")
        }
    }

    /// 트레일러 URL 목록을 생성합니다.
    static func trailerURLs(from dto: IGDBGameListDTO) -> [URL] {
        dto.videos?
            .compactMap { video in
                guard let id = video.videoId else { return nil }
                return URL(string: "https://youtu.be/\(id)")
            }
            ?? []
    }

    /// 조건에 맞는 회사 이름 목록을 반환합니다.
    static func companyNames(
        from dto: IGDBGameListDTO,
        matching predicate: (IGDBInvolvedCompanyDTO) -> Bool
    ) -> [String] {
        dto.involvedCompanies?
            .filter(predicate)
            .compactMap { $0.company?.name }
            ?? []
    }
}
