//
//  SearchViewModel.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//
//  [리팩토링] 팀장님 피드백 반영
//  - @Published는 View에서 관찰하는 것만 사용
//  - sub-ViewModel 제거, 직접 서비스 호출
//  - 프로토콜 기반 설계

import Foundation
import Combine

// MARK: - SearchViewModel

/// 게임 검색 및 필터링을 담당하는 ViewModel입니다.
///
/// - Responsibilities:
///     - IGDB API를 통한 게임 데이터 로드 (Discover, Trending, New Releases)
///     - 검색어 기반 게임 검색 및 결과 관리
///     - 플랫폼, 장르, 고급 필터 적용
///     - 무한 스크롤을 위한 페이지네이션 처리
///     - 정적 캐싱을 통한 데이터 재사용
///
/// - Important:
///     - View에서 관찰이 필요한 상태만 `@Published`로 선언합니다.
///     - 내부 상태는 `private(set)`으로 외부 변경을 방지합니다.
///     - `SearchViewModelProtocol`을 채택하여 테스트 가능한 구조를 제공합니다.
///
/// - Example:
///     ```swift
///     let viewModel = SearchViewModel(favoriteManager: favoriteManager)
///     await viewModel.loadAllGames()
///     await viewModel.performSearch(query: "zelda")
///     ```
@MainActor
final class SearchViewModel: ObservableObject, SearchViewModelProtocol {

    // MARK: - Published Properties (View에서 직접 관찰하는 것만)

    /// 필터링된 게임 목록 (View에서 표시)
    @Published private(set) var filteredItems: [GameListItem] = []

    /// 로딩 상태 (View에서 로딩 UI 표시)
    @Published private(set) var isLoading: Bool = false

    /// 에러 상태 (View에서 에러 UI 표시)
    @Published private(set) var error: Error?

    /// 검색 중 상태 (View에서 검색 로딩 표시)
    @Published private(set) var isSearching: Bool = false

    /// 장르 로딩 상태 (View에서 장르 변경 시 로딩 표시)
    @Published private(set) var isGenreLoading: Bool = false

    /// 추가 로딩 상태 (View에서 무한 스크롤 로딩 표시)
    @Published private(set) var isLoadingMore: Bool = false

    // MARK: - Internal State (View에서 관찰 불필요)

    /// 전체 아이템 (필터링 전)
    private(set) var allItems: [GameListItem] = []

    // MARK: - Private Properties

    /// 카테고리별 데이터 저장소
    private var discoverItems: [GameListItem] = []
    private var trendingItems: [GameListItem] = []
    private var newReleaseItems: [GameListItem] = []
    private var searchItems: [GameListItem] = []
    private var genreItems: [GameListItem] = []

    /// 페이지네이션 오프셋
    private var discoverOffset: Int = 0
    private var trendingOffset: Int = 0
    private var newReleaseOffset: Int = 0
    private var searchOffset: Int = 0
    private var genreOffset: Int = 0

    /// 현재 필터 상태
    private var currentPlatform: PlatformFilterType = .all
    private var currentGenre: GenreFilterType = .all
    private var currentSearchText: String = ""
    private var currentAdvancedFilter: AdvancedFilterState = AdvancedFilterState()

    /// 검색 관련
    private var lastSearchQuery: String = ""

    /// 장르 관련
    private var currentLoadedGenre: GenreFilterType = .all

    /// 의존성
    private let service: GameDataServiceProtocol
    private let favoriteManager: any FavoriteManagerProtocol
    private let pageSize: Int = 30

    // MARK: - Static Cache

    private static var cachedDiscoverItems: [GameListItem] = []
    private static var cachedTrendingItems: [GameListItem] = []
    private static var cachedNewReleaseItems: [GameListItem] = []
    private static var hasLoadedData: Bool = false

    // MARK: - Initialization

    /// 검색 ViewModel 인스턴스를 생성합니다.
    ///
    /// - Parameters:
    ///   - service: 게임 데이터 조회 서비스 (`nil`이면 `SearchGameDataService` 사용)
    ///   - favoriteManager: 즐겨찾기 상태 관리자
    init(service: GameDataServiceProtocol? = nil, favoriteManager: any FavoriteManagerProtocol) {
        self.service = service ?? SearchGameDataService()
        self.favoriteManager = favoriteManager
    }

    // MARK: - Public Methods (Protocol)

    /// 모든 카테고리(Discover, Trending, New Releases)의 게임 데이터를 로드합니다.
    ///
    /// - Endpoint:
    ///   - IGDB: `POST /v4/multiquery`
    ///   - Review: `GET /reviews/game/{gameId}/stats` (서비스 내부 결합)
    ///
    /// - Effects:
    ///     - 캐시가 존재하면 캐시 데이터 사용
    ///     - 캐시가 없으면 병렬 API 호출 후 캐시에 저장
    ///     - `isLoading` 상태 업데이트
    ///     - `FavoriteManager`에 로드된 아이템 등록
    ///
    /// - Note:
    ///     앱 재시작 전까지 정적 캐시를 통해 데이터를 재사용합니다.
    func loadAllGames() async {
        // 캐시 확인
        if Self.hasLoadedData {
            discoverItems = Self.cachedDiscoverItems
            trendingItems = Self.cachedTrendingItems
            newReleaseItems = Self.cachedNewReleaseItems
            updateAllItems()
            updateFilteredItems()
            return
        }

        isLoading = true
        error = nil

        do {
            // 병렬 API 호출
            async let discoverTask = service.fetchGames(
                query: IGDBQuery.discover,
                offset: 0,
                limit: pageSize
            )
            async let trendingTask = service.fetchGames(
                query: IGDBQuery.trendingNow,
                offset: 0,
                limit: pageSize
            )
            async let newReleaseTask = service.fetchGames(
                query: IGDBQuery.newReleases,
                offset: 0,
                limit: pageSize
            )

            let (discover, trending, newRelease) = try await (discoverTask, trendingTask, newReleaseTask)

            discoverItems = discover
            trendingItems = trending
            newReleaseItems = newRelease

            // 오프셋 업데이트
            discoverOffset = discover.count
            trendingOffset = trending.count
            newReleaseOffset = newRelease.count

            // FavoriteManager 업데이트
            favoriteManager.updateItems(discover + trending + newRelease)

            // 캐시 저장
            Self.cachedDiscoverItems = discover
            Self.cachedTrendingItems = trending
            Self.cachedNewReleaseItems = newRelease
            Self.hasLoadedData = true

            updateAllItems()
            updateFilteredItems()

        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// 캐시를 무시하고 강제로 모든 데이터를 새로고침합니다.
    ///
    /// - Endpoint:
    ///   `loadAllGames()` 내부 Endpoint 호출과 동일
    ///
    /// - Effects:
    ///     - 정적 캐시 초기화
    ///     - `loadAllGames()` 재호출
    func forceRefresh() async {
        Self.hasLoadedData = false
        await loadAllGames()
    }

    /// 검색어를 기반으로 게임을 검색합니다.
    ///
    /// - Parameter query: 검색할 게임 제목 또는 키워드
    ///
    /// - Endpoint:
    ///   - 기본 검색: IGDB `search` 쿼리
    ///   - fallback 검색: IGDB `searchFallback` 쿼리
    ///
    /// - Effects:
    ///     - 빈 검색어는 무시하고 검색 결과 초기화
    ///     - 결과가 없으면 fallback 검색 실행
    ///     - `isSearching` 상태 업데이트
    ///     - 검색 결과를 `FavoriteManager`에 등록
    func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clearSearchResults()
            return
        }

        isSearching = true
        error = nil
        lastSearchQuery = trimmed
        searchOffset = 0

        do {
            var items = try await service.fetchGames(
                query: IGDBQuery.search(trimmed),
                offset: 0,
                limit: pageSize
            )

            // 결과 없으면 fallback 검색
            if items.isEmpty {
                items = try await service.fetchGames(
                    query: IGDBQuery.searchFallback(trimmed),
                    offset: 0,
                    limit: pageSize
                )
            }

            searchItems = items
            searchOffset = items.count
            favoriteManager.updateItems(items)

            updateAllItems()
            updateFilteredItems()

        } catch {
            self.error = error
        }

        isSearching = false
    }

    /// 무한 스크롤을 위한 다음 페이지 데이터를 로드합니다.
    ///
    /// - Endpoint:
    ///   현재 상태(장르/검색/카테고리)에 따라 내부 로더가 개별 Endpoint를 호출합니다.
    ///
    /// - Effects:
    ///     - 장르 선택 시: 해당 장르의 다음 페이지 로드
    ///     - 검색 중: 검색 결과의 다음 페이지 로드
    ///     - 기본: 현재 카테고리의 다음 페이지 로드
    ///     - `isLoadingMore` 상태 업데이트
    func loadNextPage() async {
        // 장르가 선택된 경우
        if currentGenre != .all {
            await loadNextGenrePage()
            return
        }

        // 검색 중인 경우
        if !lastSearchQuery.isEmpty {
            await loadNextSearchPage()
            return
        }

        // 카테고리별 로드
        await loadNextCategoryPage()
    }

    /// 검색 결과 및 검색 상태를 초기화합니다.
    ///
    /// - Endpoint:
    ///   없음 (로컬 상태 초기화)
    ///
    /// - Effects:
    ///     - 검색 아이템 목록 비우기
    ///     - 검색어 및 오프셋 초기화
    ///     - 필터링된 결과 업데이트
    func clearSearchResults() {
        searchItems = []
        lastSearchQuery = ""
        searchOffset = 0
        isSearching = false
        updateAllItems()
        updateFilteredItems()
    }

    /// 선택된 필터 조건을 적용하여 게임 목록을 필터링합니다.
    ///
    /// - Parameters:
    ///   - platform: 플랫폼 필터 타입 (PC, PlayStation, Xbox 등)
    ///   - genre: 장르 필터 타입 (RPG, 액션, 슈팅 등)
    ///   - searchText: 로컬 검색 필터용 텍스트
    ///   - advancedFilter: 정렬, 평점, 출시 기간 등 고급 필터 상태
    ///
    /// - Endpoint:
    ///   없음 (로컬 필터 처리)
    ///
    /// - Effects:
    ///     - 필터 상태 저장
    ///     - 전체 아이템 및 필터링된 결과 업데이트
    func applyFilters(
        platform: PlatformFilterType,
        genre: GenreFilterType,
        searchText: String,
        advancedFilter: AdvancedFilterState
    ) {
        currentPlatform = platform
        currentGenre = genre
        currentSearchText = searchText
        currentAdvancedFilter = advancedFilter

        updateAllItems()
        updateFilteredItems()
    }

    // MARK: - Genre Methods

    /// 특정 장르의 게임 데이터를 서버에서 로드합니다.
    ///
    /// - Parameter genre: 로드할 장르 타입
    ///
    /// - Endpoint:
    ///   IGDB 장르 쿼리 (`IGDBQuery.genre`)
    ///
    /// - Effects:
    ///     - `.all` 장르는 장르 데이터 초기화
    ///     - 동일 장르가 이미 로드되어 있으면 스킵
    ///     - `isGenreLoading` 상태 업데이트
    ///     - 로드된 아이템을 `FavoriteManager`에 등록
    func loadGamesForGenre(_ genre: GenreFilterType) async {
        guard genre != .all, let genreId = genre.igdbGenreId else {
            currentLoadedGenre = .all
            genreItems = []
            genreOffset = 0
            updateAllItems()
            updateFilteredItems()
            return
        }

        // 이미 같은 장르가 로드되어 있으면 스킵
        if currentLoadedGenre == genre && !genreItems.isEmpty {
            return
        }

        isGenreLoading = true
        currentLoadedGenre = genre
        genreOffset = 0

        do {
            let items = try await service.fetchGames(
                query: IGDBQuery.genre(genreId),
                offset: 0,
                limit: pageSize
            )

            genreItems = items
            genreOffset = items.count
            favoriteManager.updateItems(items)

            updateAllItems()
            updateFilteredItems()

        } catch {
            self.error = error
        }

        isGenreLoading = false
    }

    /// 장르 로딩 시작 전 UI 상태를 미리 준비합니다.
    ///
    /// - Parameter genre: 로딩 예정인 장르 타입
    ///
    /// - Endpoint:
    ///   없음 (로컬 상태 준비)
    ///
    /// - Effects:
    ///     - `isGenreLoading`을 즉시 `true`로 설정
    ///     - 기존 장르 아이템 초기화
    ///
    /// - Note:
    ///     `loadGamesForGenre` 호출 전에 사용하여 즉각적인 로딩 UI를 표시합니다.
    func prepareGenreLoading(_ genre: GenreFilterType) {
        guard genre != .all else { return }
        isGenreLoading = true
        genreItems = []
    }

    // MARK: - Helper Methods

    /// 현재 원격 검색이 활성화되어 있는지 확인합니다.
    ///
    /// - Parameter searchText: 현재 검색 텍스트
    /// - Returns: 마지막 검색어와 현재 검색 텍스트가 일치하면 `true`
    func isRemoteSearchActive(searchText: String) -> Bool {
        !lastSearchQuery.isEmpty &&
        lastSearchQuery == searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 현재 필터 상태에 따른 결과 헤더 타이틀을 생성합니다.
    ///
    /// - Parameters:
    ///   - platform: 선택된 플랫폼 필터
    ///   - genre: 선택된 장르 필터
    /// - Returns: 필터 조합에 맞는 헤더 문자열 (예: "PC · RPG 게임")
    func headerTitle(platform: PlatformFilterType, genre: GenreFilterType) -> String {
        var components: [String] = []

        if platform != .all {
            components.append(platform.rawValue)
        }

        if genre != .all {
            components.append(genre.displayName)
        }

        if components.isEmpty {
            return "추천 게임"
        }

        return components.joined(separator: " · ") + " 게임"
    }

    // MARK: - Private Methods

    /// 검색 결과의 다음 페이지를 로드합니다.
    ///
    /// - Endpoint:
    ///   IGDB 검색 쿼리 (`IGDBQuery.search`)
    private func loadNextSearchPage() async {
        guard !lastSearchQuery.isEmpty else { return }

        isLoadingMore = true

        do {
            let items = try await service.fetchGames(
                query: IGDBQuery.search(lastSearchQuery),
                offset: searchOffset,
                limit: pageSize
            )

            searchItems.append(contentsOf: items)
            searchOffset += items.count
            favoriteManager.updateItems(items)

            updateAllItems()
            updateFilteredItems()

        } catch {
            self.error = error
        }

        isLoadingMore = false
    }

    /// 장르 필터링된 결과의 다음 페이지를 로드합니다.
    ///
    /// - Endpoint:
    ///   IGDB 장르 쿼리 (`IGDBQuery.genre`)
    private func loadNextGenrePage() async {
        guard let genreId = currentLoadedGenre.igdbGenreId else { return }

        isLoadingMore = true

        do {
            let items = try await service.fetchGames(
                query: IGDBQuery.genre(genreId),
                offset: genreOffset,
                limit: pageSize
            )

            genreItems.append(contentsOf: items)
            genreOffset += items.count
            favoriteManager.updateItems(items)

            updateAllItems()
            updateFilteredItems()

        } catch {
            self.error = error
        }

        isLoadingMore = false
    }

    /// 현재 선택된 카테고리의 다음 페이지를 로드합니다.
    ///
    /// - Endpoint:
    ///   - `.all`: Discover/Trending/NewReleases 병렬 호출
    ///   - 단일 카테고리: 해당 카테고리 쿼리 단건 호출
    private func loadNextCategoryPage() async {
        isLoadingMore = true

        do {
            switch currentAdvancedFilter.category {
            case .all:
                // 모든 카테고리 병렬 로드
                async let d = service.fetchGames(query: IGDBQuery.discover, offset: discoverOffset, limit: pageSize)
                async let t = service.fetchGames(query: IGDBQuery.trendingNow, offset: trendingOffset, limit: pageSize)
                async let n = service.fetchGames(query: IGDBQuery.newReleases, offset: newReleaseOffset, limit: pageSize)

                let (discover, trending, newRelease) = try await (d, t, n)

                discoverItems.append(contentsOf: discover)
                trendingItems.append(contentsOf: trending)
                newReleaseItems.append(contentsOf: newRelease)

                discoverOffset += discover.count
                trendingOffset += trending.count
                newReleaseOffset += newRelease.count

                favoriteManager.updateItems(discover + trending + newRelease)

            case .discover:
                let items = try await service.fetchGames(query: IGDBQuery.discover, offset: discoverOffset, limit: pageSize)
                discoverItems.append(contentsOf: items)
                discoverOffset += items.count
                favoriteManager.updateItems(items)

            case .trending:
                let items = try await service.fetchGames(query: IGDBQuery.trendingNow, offset: trendingOffset, limit: pageSize)
                trendingItems.append(contentsOf: items)
                trendingOffset += items.count
                favoriteManager.updateItems(items)

            case .newReleases:
                let items = try await service.fetchGames(query: IGDBQuery.newReleases, offset: newReleaseOffset, limit: pageSize)
                newReleaseItems.append(contentsOf: items)
                newReleaseOffset += items.count
                favoriteManager.updateItems(items)
            }

            updateAllItems()
            updateFilteredItems()

        } catch {
            self.error = error
        }

        isLoadingMore = false
    }

    /// 현재 상태에 따라 표시할 전체 아이템 목록을 업데이트합니다.
    ///
    /// - Note:
    ///     우선순위: 검색 결과 > 장르 데이터 > 카테고리 데이터
    private func updateAllItems() {
        let trimmedSearch = currentSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isRemoteSearch = !lastSearchQuery.isEmpty && lastSearchQuery == trimmedSearch

        // 검색 결과 우선
        if isRemoteSearch {
            allItems = searchItems
            return
        }

        // 장르 선택 시
        if currentGenre != .all && !genreItems.isEmpty {
            allItems = genreItems
            return
        }

        // 카테고리별
        let items: [GameListItem]
        switch currentAdvancedFilter.category {
        case .all:
            items = discoverItems + trendingItems + newReleaseItems
        case .trending:
            items = trendingItems
        case .newReleases:
            items = newReleaseItems
        case .discover:
            items = discoverItems
        }

        // 중복 제거
        var seen = Set<Int>()
        allItems = items.filter { item in
            guard !seen.contains(item.id) else { return false }
            seen.insert(item.id)
            return true
        }
    }

    /// 현재 필터 조건을 적용하여 필터링된 결과를 업데이트합니다.
    ///
    /// - Note:
    ///     플랫폼, 장르, 검색어, 평점, 출시 기간 필터 순차 적용 후 정렬
    private func updateFilteredItems() {
        let trimmedSearch = currentSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isRemoteSearch = !lastSearchQuery.isEmpty && lastSearchQuery == trimmedSearch

        var result = allItems.filter { item in
            // 플랫폼 필터
            let matchesPlatform = currentPlatform == .all ||
                item.platformCategories.contains { currentPlatform.matches($0) }

            // 장르 필터
            let matchesGenre = currentGenre == .all ||
                item.genre.contains { currentGenre.matches(genre: $0) }

            // 검색 필터
            let matchesSearch = isRemoteSearch || trimmedSearch.isEmpty ||
                item.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                item.genre.joined(separator: " ").localizedCaseInsensitiveContains(trimmedSearch)

            // 평점 필터
            let matchesRating = currentAdvancedFilter.minimumRating <= 0 ||
                item.ratingValue >= currentAdvancedFilter.minimumRating

            // 출시 기간 필터
            let matchesPeriod = currentAdvancedFilter.releasePeriod.matches(releaseYear: item.releaseYearText)

            return matchesPlatform && matchesGenre && matchesSearch && matchesRating && matchesPeriod
        }

        // 정렬
        result = sortItems(result)
        filteredItems = result
    }

    /// 고급 필터의 정렬 타입에 따라 아이템을 정렬합니다.
    ///
    /// - Parameter items: 정렬할 게임 아이템 배열
    /// - Returns: 정렬된 게임 아이템 배열
    private func sortItems(_ items: [GameListItem]) -> [GameListItem] {
        switch currentAdvancedFilter.sortType {
        case .popularity:
            return items
        case .newest:
            return items.sorted { (Int($0.releaseYearText) ?? 0) > (Int($1.releaseYearText) ?? 0) }
        case .rating:
            return items.sorted { $0.ratingValue > $1.ratingValue }
        case .nameAsc:
            return items.sorted { $0.title < $1.title }
        }
    }
}
