//
//  SearchViewModel.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//
//  [수정] Game → GameListItem 통일

import Foundation
import Combine

/// SearchView를 위한 통합 ViewModel
/// 여러 카테고리의 게임 데이터를 관리
@MainActor
final class SearchViewModel: ObservableObject {

    // MARK: - Static Cache (API 중복 호출 방지)
    private static var cachedDiscoverItems: [GameListItem] = []
    private static var cachedTrendingItems: [GameListItem] = []
    private static var cachedNewReleaseItems: [GameListItem] = []
    private static var hasLoadedData: Bool = false

    // MARK: - Published Properties
    // [수정] Game → GameListItem
    @Published var discoverItems: [GameListItem] = []
    @Published var trendingItems: [GameListItem] = []
    @Published var newReleaseItems: [GameListItem] = []
    @Published var searchItems: [GameListItem] = []

    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var isSearching: Bool = false
    @Published var isSearchLoadingMore: Bool = false
    @Published var error: Error?
    @Published var searchError: Error?
    @Published var lastSearchQuery: String = ""

    // MARK: - [수정] 필터링된 결과 (View에서 ViewModel로 이동)
    @Published private(set) var filteredItems: [GameListItem] = []
    @Published private(set) var allItems: [GameListItem] = []

    // 현재 필터 상태 저장
    private var currentPlatform: PlatformFilterType = .all
    private var currentGenre: GenreFilterType = .all
    private var currentSearchText: String = ""
    private var currentAdvancedFilter: AdvancedFilterState = AdvancedFilterState()

    // MARK: - Private Properties
    private let service: IGDBService
    private let favoriteManager: FavoriteManager

    // 각 카테고리별 ViewModel
    private var discoverViewModel: GameListSingleQueryViewModel?
    private var trendingViewModel: GameListSingleQueryViewModel?
    private var newReleasesViewModel: GameListSingleQueryViewModel?
    private var searchViewModel: GameListSingleQueryViewModel?

    // [추가] 장르별 ViewModel (서버 사이드 필터링)
    private var genreViewModel: GameListSingleQueryViewModel?
    @Published var genreItems: [GameListItem] = []
    @Published var isGenreLoading: Bool = false
    @Published var isGenreLoadingMore: Bool = false
    private var currentLoadedGenre: GenreFilterType = .all

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(service: IGDBService = IGDBServiceManager(), favoriteManager: FavoriteManager) {
        self.service = service
        self.favoriteManager = favoriteManager
        setupViewModels()
    }

    // MARK: - Setup
    private func setupViewModels() {
        // Discover용 ViewModel
        discoverViewModel = GameListSingleQueryViewModel(
            service: service,
            query: IGDBQuery.discover
        )

        // Trending용 ViewModel
        trendingViewModel = GameListSingleQueryViewModel(
            service: service,
            query: IGDBQuery.trendingNow
        )

        // New Releases용 ViewModel
        newReleasesViewModel = GameListSingleQueryViewModel(
            service: service,
            query: IGDBQuery.newReleases
        )

        // ViewModel의 변화를 구독
        observeViewModels()
    }

    private func observeViewModels() {
        // [수정] Discover 데이터 변화 감지 - Game 변환 제거
        discoverViewModel?.$items
            .sink { [weak self] items in
                self?.discoverItems = items
                self?.favoriteManager.updateItems(items)
            }
            .store(in: &cancellables)

        // [수정] Trending 데이터 변화 감지 - Game 변환 제거
        trendingViewModel?.$items
            .sink { [weak self] items in
                self?.trendingItems = items
                self?.favoriteManager.updateItems(items)
            }
            .store(in: &cancellables)

        // [수정] New Releases 데이터 변화 감지 - Game 변환 제거
        newReleasesViewModel?.$items
            .sink { [weak self] items in
                self?.newReleaseItems = items
                self?.favoriteManager.updateItems(items)
            }
            .store(in: &cancellables)

        // 로딩 상태 통합
        Publishers.CombineLatest3(
            discoverViewModel?.$isLoading.eraseToAnyPublisher() ?? Just(false).eraseToAnyPublisher(),
            trendingViewModel?.$isLoading.eraseToAnyPublisher() ?? Just(false).eraseToAnyPublisher(),
            newReleasesViewModel?.$isLoading.eraseToAnyPublisher() ?? Just(false).eraseToAnyPublisher()
        )
        .map { $0 || $1 || $2 }
        .sink { [weak self] isLoading in
            self?.isLoading = isLoading
        }
        .store(in: &cancellables)

        // 추가 로딩 상태 통합
        Publishers.CombineLatest3(
            discoverViewModel?.$isLoadingMore.eraseToAnyPublisher() ?? Just(false).eraseToAnyPublisher(),
            trendingViewModel?.$isLoadingMore.eraseToAnyPublisher() ?? Just(false).eraseToAnyPublisher(),
            newReleasesViewModel?.$isLoadingMore.eraseToAnyPublisher() ?? Just(false).eraseToAnyPublisher()
        )
        .map { $0 || $1 || $2 }
        .sink { [weak self] isLoadingMore in
            self?.isLoadingMore = isLoadingMore
        }
        .store(in: &cancellables)

        // 에러 처리
        Publishers.Merge3(
            discoverViewModel?.$error.compactMap { $0 }.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher(),
            trendingViewModel?.$error.compactMap { $0 }.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher(),
            newReleasesViewModel?.$error.compactMap { $0 }.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
        )
        .sink { [weak self] error in
            self?.error = error
        }
        .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// 모든 카테고리 데이터 로드 (캐시된 데이터가 있으면 사용)
    /// [수정] 순차 호출 → 병렬 호출로 변경하여 로딩 속도 약 66% 개선
    func loadAllGames() async {
        // 이미 캐시된 데이터가 있으면 캐시에서 불러오기
        if SearchViewModel.hasLoadedData {
            self.discoverItems = SearchViewModel.cachedDiscoverItems
            self.trendingItems = SearchViewModel.cachedTrendingItems
            self.newReleaseItems = SearchViewModel.cachedNewReleaseItems
            return
        }

        // [수정] 처음 로드하는 경우 API 병렬 호출
        async let discoverTask: ()? = discoverViewModel?.load()
        async let trendingTask: ()? = trendingViewModel?.load()
        async let newReleasesTask: ()? = newReleasesViewModel?.load()
        _ = await (discoverTask, trendingTask, newReleasesTask)

        // 캐시에 저장
        SearchViewModel.cachedDiscoverItems = self.discoverItems
        SearchViewModel.cachedTrendingItems = self.trendingItems
        SearchViewModel.cachedNewReleaseItems = self.newReleaseItems
        SearchViewModel.hasLoadedData = true
    }

    /// 강제로 새로고침 (pull-to-refresh용)
    /// [수정] 순차 호출 → 병렬 호출로 변경
    func forceRefreshAllGames() async {
        SearchViewModel.hasLoadedData = false

        // [수정] API 병렬 호출
        async let discoverTask: ()? = discoverViewModel?.load()
        async let trendingTask: ()? = trendingViewModel?.load()
        async let newReleasesTask: ()? = newReleasesViewModel?.load()
        _ = await (discoverTask, trendingTask, newReleasesTask)

        // 캐시 업데이트
        SearchViewModel.cachedDiscoverItems = self.discoverItems
        SearchViewModel.cachedTrendingItems = self.trendingItems
        SearchViewModel.cachedNewReleaseItems = self.newReleaseItems
        SearchViewModel.hasLoadedData = true
    }

    /// 특정 카테고리만 새로고침
    func refreshDiscover() async {
        await discoverViewModel?.load()
    }

    func refreshTrending() async {
        await trendingViewModel?.load()
    }

    func refreshNewReleases() async {
        await newReleasesViewModel?.load()
    }

    /// 검색어 기반 서버 검색
    func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clearSearchResults()
            return
        }

        isSearching = true
        searchError = nil
        lastSearchQuery = trimmed

        var vm = GameListSingleQueryViewModel(
            service: service,
            query: IGDBQuery.search(trimmed)
        )
        await vm.load()

        if vm.items.isEmpty {
            vm = GameListSingleQueryViewModel(
                service: service,
                query: IGDBQuery.searchFallback(trimmed)
            )
            await vm.load()
        }

        searchViewModel = vm
        self.searchItems = vm.items
        self.searchError = vm.error
        isSearching = false
    }

    func loadNextSearchPage() async {
        guard let vm = searchViewModel else { return }
        isSearchLoadingMore = true
        defer { isSearchLoadingMore = false }

        await vm.loadNextPage()
        self.searchItems = vm.items
        self.searchError = vm.error
    }

    func clearSearchResults() {
        searchItems = []
        searchError = nil
        lastSearchQuery = ""
        isSearching = false
        isSearchLoadingMore = false
        searchViewModel = nil
    }

    /// 스크롤 하단 도달 시 다음 페이지 로드
    func loadNext(for category: CategoryFilter) async {
        // [수정] 장르가 선택된 경우 장르별 다음 페이지 로드
        if currentGenre != .all {
            await loadNextGenrePage()
            return
        }

        switch category {
        case .all:
            await loadNextAll()
        case .trending:
            await trendingViewModel?.loadNextPage()
        case .newReleases:
            await newReleasesViewModel?.loadNextPage()
        case .discover:
            await discoverViewModel?.loadNextPage()
        }
    }

    /// [수정] 순차 호출 → 병렬 호출로 변경
    private func loadNextAll() async {
        async let d: ()? = discoverViewModel?.loadNextPage()
        async let t: ()? = trendingViewModel?.loadNextPage()
        async let n: ()? = newReleasesViewModel?.loadNextPage()
        _ = await (d, t, n)
    }

    // MARK: - [추가] 장르별 서버 사이드 필터링

    /// 특정 장르의 게임을 서버에서 로드
    func loadGamesForGenre(_ genre: GenreFilterType) async {
        // 전체인 경우 기존 데이터 사용
        guard genre != .all, let genreId = genre.igdbGenreId else {
            currentLoadedGenre = .all
            genreItems = []
            genreViewModel = nil
            return
        }

        // 이미 같은 장르가 로드되어 있으면 스킵
        if currentLoadedGenre == genre && !genreItems.isEmpty {
            return
        }

        isGenreLoading = true
        currentLoadedGenre = genre

        let vm = GameListSingleQueryViewModel(
            service: service,
            query: IGDBQuery.genre(genreId)
        )
        await vm.load()

        genreViewModel = vm
        genreItems = vm.items
        favoriteManager.updateItems(vm.items)
        isGenreLoading = false

        // 필터 다시 적용
        updateAllItems()
        updateFilteredItems()
    }

    /// 장르별 다음 페이지 로드
    func loadNextGenrePage() async {
        guard let vm = genreViewModel else { return }
        isGenreLoadingMore = true

        await vm.loadNextPage()
        genreItems = vm.items
        favoriteManager.updateItems(vm.items)
        isGenreLoadingMore = false

        // 필터 다시 적용
        updateAllItems()
        updateFilteredItems()
    }

    // MARK: - [수정] 필터링 로직 (View에서 ViewModel로 이동)

    /// 필터 적용 및 결과 업데이트
    /// - Parameters:
    ///   - platform: 플랫폼 필터
    ///   - genre: 장르 필터
    ///   - searchText: 검색어
    ///   - advancedFilter: 고급 필터 상태
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

    /// 원본 데이터 업데이트 (카테고리 기반)
    /// [수정] 장르 선택 시 서버에서 로드한 genreItems 사용
    private func updateAllItems() {
        let isRemoteSearch = !lastSearchQuery.isEmpty &&
            lastSearchQuery == currentSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if isRemoteSearch {
            allItems = searchItems
            return
        }

        // [수정] 장르가 선택된 경우 서버에서 로드한 데이터 사용
        if currentGenre != .all && !genreItems.isEmpty {
            allItems = genreItems
            return
        }

        // 카테고리에 따라 데이터 소스 선택
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
            if seen.contains(item.id) { return false }
            seen.insert(item.id)
            return true
        }
    }

    /// 필터링된 결과 업데이트
    private func updateFilteredItems() {
        let isRemoteSearch = !lastSearchQuery.isEmpty &&
            lastSearchQuery == currentSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        var result = allItems.filter { item in
            let matchesPlatform = filterByPlatform(item: item, platform: currentPlatform)
            let matchesGenre = filterByGenre(item: item, genre: currentGenre)
            let matchesSearch = isRemoteSearch
                ? true
                : (currentSearchText.isEmpty ||
                    item.title.localizedCaseInsensitiveContains(currentSearchText) ||
                    item.genre.joined(separator: " ").localizedCaseInsensitiveContains(currentSearchText))
            let matchesRating = filterByRating(item: item)
            let matchesReleasePeriod = currentAdvancedFilter.releasePeriod.matches(releaseYear: item.releaseYearText)

            return matchesPlatform && matchesGenre && matchesSearch && matchesRating && matchesReleasePeriod
        }

        // 정렬 적용
        result = sortItems(result)
        filteredItems = result
    }

    /// 플랫폼 필터 적용
    private func filterByPlatform(item: GameListItem, platform: PlatformFilterType) -> Bool {
        guard platform != .all else { return true }
        return item.platformCategories.contains { platform.matches($0) }
    }

    /// 장르 필터 적용
    private func filterByGenre(item: GameListItem, genre: GenreFilterType) -> Bool {
        guard genre != .all else { return true }
        return item.genre.contains { genreString in
            genre.matches(genre: genreString)
        }
    }

    /// 평점 필터 적용
    private func filterByRating(item: GameListItem) -> Bool {
        guard currentAdvancedFilter.minimumRating > 0 else { return true }

        guard item.ratingText != "N/A",
              let rating = Double(item.ratingText) else {
            return false
        }

        return rating >= currentAdvancedFilter.minimumRating
    }

    /// 정렬 적용
    private func sortItems(_ items: [GameListItem]) -> [GameListItem] {
        switch currentAdvancedFilter.sortType {
        case .popularity:
            return items
        case .newest:
            return items.sorted { item1, item2 in
                let year1 = Int(item1.releaseYearText) ?? 0
                let year2 = Int(item2.releaseYearText) ?? 0
                return year1 > year2
            }
        case .rating:
            return items.sorted { item1, item2 in
                let rating1 = Double(item1.ratingText) ?? 0
                let rating2 = Double(item2.ratingText) ?? 0
                return rating1 > rating2
            }
        case .nameAsc:
            return items.sorted { $0.title < $1.title }
        }
    }

    /// 원격 검색 활성화 여부
    func isRemoteSearchActive(searchText: String) -> Bool {
        !lastSearchQuery.isEmpty &&
            lastSearchQuery == searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 헤더 타이틀 생성
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
}
