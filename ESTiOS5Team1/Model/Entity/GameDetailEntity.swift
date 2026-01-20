//
//  GameDetailEntity.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation

/// 게임 상세 화면에 필요한 필드를 모은 엔티티입니다.
struct GameDetailEntity {
    let id: Int
    let title: String
    let coverURL: URL?
    let summary: String?
    let storyline: String?
    let metaScore: Double?       // aggregated_rating
    let releaseYear: Int?
    let genres: [String]
    let platforms: [GamePlatform]
    let rating: Double?
}

extension GameDetailEntity {
    init(dto: IGDBGameListDTO) {
        self.id = dto.id
        self.title = dto.name

        if let imageID = dto.cover?.imageID {
            self.coverURL = makeIGDBImageURL(imageID: imageID)
        } else {
            self.coverURL = nil
        }

        self.summary = dto.summary
        self.storyline = dto.storyline

        self.metaScore = dto.aggregatedRating

        if let years = dto.releaseDates?.compactMap({ $0.year }), let latest = years.max() {
            self.releaseYear = latest
        } else {
            self.releaseYear = nil
        }

        self.genres = dto.genres?.map { $0.name } ?? []

        self.platforms = dto.platforms?.map {
            GamePlatform(name: $0.name)
        } ?? []

        self.rating = dto.rating

    }
}
