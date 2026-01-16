//
//  GameDetailItem.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation

struct GameDetailItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let coverURL: URL?
    let metaScore: String
    let releaseYear: String
    let summary: String?
    let description: String?
    let genre: [String]
    let platforms: [Platform]
    let ratingText: String
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
        self.platforms = Array(
            Set(detail.platforms.compactMap { Platform(igdbName: $0.name) })
        )
    }
}
