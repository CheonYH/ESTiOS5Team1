//
//  Protocols.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/29/26.
//
//  [리팩토링] 프로토콜 기반 설계로 의존성 주입 및 테스트 용이성 확보

import Foundation
import Combine

// MARK: - Game Data Service Protocol

/// 게임 데이터를 로드하는 서비스 프로토콜입니다.
protocol GameDataServiceProtocol {
    /// IGDB 쿼리를 기반으로 게임 목록을 조회합니다.
    /// - Parameters:
    ///   - query: IGDB API 쿼리 문자열
    ///   - offset: 페이지네이션 오프셋
    ///   - limit: 한 번에 가져올 게임 수
    /// - Returns: 조회된 GameListItem 배열
    func fetchGames(query: String, offset: Int, limit: Int) async throws -> [GameListItem]
}

// MARK: - Search ViewModel Protocol

/// SearchView에서 사용하는 ViewModel 프로토콜입니다.
@MainActor
protocol SearchViewModelProtocol: ObservableObject {
    var filteredItems: [GameListItem] { get }
    var isLoading: Bool { get }
    var error: Error? { get }

    func loadAllGames() async
    func performSearch(query: String) async
    func loadNextPage() async
    func clearSearchResults()
    func applyFilters(
        platform: PlatformFilterType,
        genre: GenreFilterType,
        searchText: String,
        advancedFilter: AdvancedFilterState
    )
}

// MARK: - Favorite Manager Protocol

/// 즐겨찾기 관리 프로토콜입니다.
@MainActor
protocol FavoriteManagerProtocol: ObservableObject {
    var favoriteItems: [GameListItem] { get }
    func isFavorite(itemId: Int) -> Bool
    func toggleFavorite(item: GameListItem)
    func updateItems(_ items: [GameListItem])
}

// MARK: - IGDBService Extension (프로토콜 채택)

// MARK: - IGDBService Extension

extension IGDBServiceManager: GameDataServiceProtocol {
    func fetchGames(query: String, offset: Int = 0, limit: Int = 30) async throws -> [GameListItem] {
        // 기존 limit/offset 제거 후 새로 추가 (중복 방지)
        let strippedQuery = query
            .replacingOccurrences(
                of: #"(?m)^\s*limit\s+\d+\s*;\s*$"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"(?m)^\s*offset\s+\d+\s*;\s*$"#,
                with: "",
                options: .regularExpression
            )

        // 페이지네이션이 포함된 쿼리 생성
        let pagedQuery = """
        \(strippedQuery)
        limit \(limit);
        offset \(offset);
        """

        // IGDBBatchItem으로 멀티쿼리 요청
        let batch = [
            IGDBBatchItem(name: "searchList", endpoint: .games, query: pagedQuery)
        ]

        // API 호출
        let sections = try await fetch(batch)
        guard let raw = sections["searchList"] else { return [] }

        // JSON 파싱 → DTO → Entity
        let data = try JSONSerialization.data(withJSONObject: raw)
        let dtos = try JSONDecoder().decode([IGDBGameListDTO].self, from: data)
        let entities = dtos.map(GameEntity.init)

        // MainActor에서 GameListItem 생성 (GameListItem이 @MainActor이므로)
        return await MainActor.run {
            let emptyReview = GameReviewEntity(reviews: [], stats: nil, myReview: nil)
            return entities.map { GameListItem(entity: $0, review: emptyReview) }
        }
    }
}
