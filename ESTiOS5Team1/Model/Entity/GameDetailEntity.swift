//
//  GameDetailEntity.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation

enum Store: Hashable {
    case steam
    case playstation
    case xbox
    case epic
    case nintendo
    case gog
    case other(String)
}

struct StoreLink: Hashable {
    let store: Store
    let url: URL
}

/// 게임 상세 화면에 필요한 필드를 모은 엔티티입니다.
struct GameDetailEntity {
    let id: Int
    let title: String
    let coverURL: URL?
    let summary: String?
    let storyline: String?
    let metaScore: Double?
    let releaseYear: Int?
    let genres: [String]
    let platforms: [GamePlatform]
    let rating: Double?

    let storeLinks: [StoreLink]
    let officialWebsite: URL?
    let trailerUrls: [URL]
    let developers: [String]
    let publishers: [String]
}

extension GameDetailEntity {
    init(dto: IGDBGameListDTO) {
        self.id = dto.id
        self.title = dto.name

        self.coverURL = Self.makeCoverURL(from: dto)

        self.summary = dto.summary
        self.storyline = dto.storyline
        self.metaScore = dto.aggregatedRating

        self.releaseYear = Self.latestReleaseYear(from: dto)

        self.genres = dto.genres?.map { $0.name } ?? []
        self.platforms = dto.platforms?.map { GamePlatform(name: $0.name) } ?? []
        self.rating = dto.rating

        self.officialWebsite = Self.officialWebsite(from: dto)

        // 🔹 store links
        self.storeLinks = Self.storeLinks(from: dto)

        // 🔹 트레일러 (Youtube ID)
        self.trailerUrls = Self.trailerURLs(from: dto)

        // 🔹 개발사
        self.developers = Self.companyNames(from: dto, matching: { $0.developer == true })

        // 🔹 배급사 / 유통사
        self.publishers = Self.companyNames(from: dto, matching: { $0.publisher == true })
    }
}

private extension GameDetailEntity {
    static func makeCoverURL(from dto: IGDBGameListDTO) -> URL? {
        guard let imageID = dto.cover?.imageID else { return nil }
        return makeIGDBImageURL(imageID: imageID)
    }

    static func latestReleaseYear(from dto: IGDBGameListDTO) -> Int? {
        dto.releaseDates?.compactMap { $0.year }.max()
    }

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

    static func storeLinks(from dto: IGDBGameListDTO) -> [StoreLink] {
        dto.websites?
            .compactMap { site in
                guard let urlString = site.url,
                      let url = URL(string: urlString) else { return nil }
                if let category = site.category {
                    switch category {
                    case 5:  return StoreLink(store: .steam, url: url)
                    case 10: return StoreLink(store: .epic, url: url)
                    case 13: return StoreLink(store: .nintendo, url: url)
                    case 14: return StoreLink(store: .xbox, url: url)
                    case 15: return StoreLink(store: .playstation, url: url)
                    case 6, 11:
                        return StoreLink(store: .gog, url: url)
                    default:
                        return StoreLink(store: .other("unknown"), url: url)
                    }
                }

                let host = url.host?.lowercased() ?? ""
                switch true {
                case host.contains("steampowered"):
                    return StoreLink(store: .steam, url: url)
                case host.contains("playstation"):
                    return StoreLink(store: .playstation, url: url)
                case host.contains("xbox"):
                    return StoreLink(store: .xbox, url: url)
                case host.contains("nintendo"):
                    return StoreLink(store: .nintendo, url: url)
                case host.contains("epicgames"):
                    return StoreLink(store: .epic, url: url)
                case host.contains("gog"):
                    return StoreLink(store: .gog, url: url)
                default:
                    return StoreLink(store: .other("unknown"), url: url)
                }
            } ?? []
    }

    static func trailerURLs(from dto: IGDBGameListDTO) -> [URL] {
        dto.videos?
            .compactMap { video in
                guard let id = video.videoId else { return nil }
                return URL(string: "https://youtu.be/\(id)")
            }
            ?? []
    }

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
