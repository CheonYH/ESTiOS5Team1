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

/// 게임 데이터를 로드하는 서비스의 추상화 프로토콜입니다.
///
/// - Responsibilities:
///     - IGDB API 쿼리를 통한 게임 목록 조회
///     - 페이지네이션을 위한 offset/limit 지원
///
/// - Important:
///     의존성 주입(DI)을 통해 테스트 시 Mock 객체로 대체할 수 있습니다.
///
/// - Example:
///     ```swift
///     // 실제 구현체 사용
///     let service: GameDataServiceProtocol = IGDBServiceManager()
///
///     // Mock 구현체 (테스트용)
///     let mockService: GameDataServiceProtocol = MockGameDataService()
///     ```
protocol GameDataServiceProtocol {

    /// IGDB 쿼리를 기반으로 게임 목록을 조회합니다.
    ///
    /// - Parameters:
    ///   - query: IGDB API 쿼리 문자열
    ///   - offset: 페이지네이션 오프셋 (시작 위치)
    ///   - limit: 한 번에 가져올 게임 수
    /// - Returns: 조회된 `GameListItem` 배열
    /// - Throws: 네트워크 오류 또는 파싱 오류
    func fetchGames(query: String, offset: Int, limit: Int) async throws -> [GameListItem]
}

// MARK: - Search ViewModel Protocol

/// SearchView에서 사용하는 ViewModel의 추상화 프로토콜입니다.
///
/// - Responsibilities:
///     - 게임 목록 로드 및 검색 기능 정의
///     - 필터 적용 및 페이지네이션 인터페이스 제공
///     - View에서 관찰할 상태 속성 정의
///
/// - Important:
///     - `@MainActor`로 선언되어 모든 작업이 메인 스레드에서 실행됩니다.
///     - View는 구현체가 아닌 이 프로토콜에만 의존하여 결합도를 낮춥니다.
///
/// - Example:
///     ```swift
///     @StateObject var viewModel: some SearchViewModelProtocol = SearchViewModel(...)
///     ```
@MainActor
protocol SearchViewModelProtocol: ObservableObject {

    // MARK: - View에서 관찰하는 상태 (필수)

    /// 필터링된 게임 목록
    var filteredItems: [GameListItem] { get }

    /// 초기 로딩 상태
    var isLoading: Bool { get }

    /// 에러 상태 (nil이면 에러 없음)
    var error: Error? { get }

    // MARK: - 메서드 (필수)

    /// 모든 카테고리의 게임 데이터를 로드합니다.
    func loadAllGames() async

    /// 검색어로 게임을 검색합니다.
    func performSearch(query: String) async

    /// 다음 페이지 데이터를 로드합니다.
    func loadNextPage() async

    /// 검색 결과를 초기화합니다.
    func clearSearchResults()

    /// 필터 조건을 적용합니다.
    func applyFilters(
        platform: PlatformFilterType,
        genre: GenreFilterType,
        searchText: String,
        advancedFilter: AdvancedFilterState
    )
}

// MARK: - Favorite Manager Protocol

/// 즐겨찾기 관리 기능의 추상화 프로토콜입니다.
///
/// - Responsibilities:
///     - 즐겨찾기 상태 확인 및 토글
///     - 즐겨찾기된 게임 목록 제공
///     - 게임 아이템 캐시 업데이트
///
/// - Important:
///     `@MainActor`로 선언되어 UI 바인딩에 안전합니다.
@MainActor
protocol FavoriteManagerProtocol: ObservableObject {

    /// 즐겨찾기된 게임 아이템 목록
    var favoriteItems: [GameListItem] { get }

    /// 특정 게임의 즐겨찾기 여부를 확인합니다.
    func isFavorite(itemId: Int) -> Bool

    /// 게임의 즐겨찾기 상태를 토글합니다.
    func toggleFavorite(item: GameListItem)

    /// 게임 아이템을 내부 캐시에 추가합니다.
    func updateItems(_ items: [GameListItem])
}

// MARK: - IGDBService Extension (프로토콜 채택)

/// IGDBServiceManager의 GameDataServiceProtocol 채택 구현입니다.
///
/// - Note:
///     기존 IGDB 서비스를 SearchViewModel에서 사용할 수 있도록
///     프로토콜 어댑터 역할을 합니다.
extension IGDBServiceManager: GameDataServiceProtocol {

    /// IGDB 쿼리를 실행하여 게임 목록을 반환합니다.
    ///
    /// - Parameters:
    ///   - query: IGDB 쿼리 문자열 (limit/offset은 자동 처리)
    ///   - offset: 페이지네이션 시작 위치
    ///   - limit: 가져올 게임 수
    /// - Returns: `GameListItem` 배열
    /// - Throws: 네트워크 또는 JSON 파싱 오류
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
