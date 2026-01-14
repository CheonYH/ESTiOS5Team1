//
//  Game.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//

import SwiftUI

// MARK: - Game Model
/// 앱 전체에서 사용하는 통합 게임 모델
/// GameListItem을 래핑하여 기존 UI 코드와 호환성 유지
struct Game: Identifiable, Hashable {
    let id: String
    let title: String
    let genre: String
    let releaseYear: String
    let ratingText: String
    let coverURL: URL?
    let platforms: [Platform]

    /// GameListItem으로부터 Game 생성
    init(from item: GameListItem) {
        self.id = String(item.id)
        self.title = item.title
        self.genre = item.genre.first ?? "Unknown"
        self.releaseYear = "-" // API에서 제공하지 않음
        self.ratingText = item.ratingText
        self.coverURL = item.coverURL
        self.platforms = item.platformCategories
    }

    /// 테스트/프리뷰용 직접 초기화
    init(
        id: String,
        title: String,
        genre: String,
        releaseYear: String,
        ratingText: String = "N/A",
        coverURL: URL? = nil,
        platforms: [Platform]
    ) {
        self.id = id
        self.title = title
        self.genre = genre
        self.releaseYear = releaseYear
        self.ratingText = ratingText
        self.coverURL = coverURL
        self.platforms = platforms
    }
}

// MARK: - Backward Compatibility
extension Game {
    /// 기존 코드와의 호환성을 위한 imageName 프로퍼티
    /// coverURL이 있으면 사용하고, 없으면 빈 문자열 반환
    var imageName: String {
        coverURL?.absoluteString ?? ""
    }
}
