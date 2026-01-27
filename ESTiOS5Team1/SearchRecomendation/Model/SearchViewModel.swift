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

    // MARK: - Private Properties
    private let service: IGDBService
    private let favoriteManager: FavoriteManager

    // 각 카테고리별 ViewModel
    private var discoverViewModel: GameListSingleQueryViewModel?
    private var trendingViewModel: GameListSingleQueryViewModel?
    private var newReleasesViewModel: GameListSingleQueryViewModel?
    private var searchViewModel: GameListSingleQueryViewModel?

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
    func loadAllGames() async {
        // 이미 캐시된 데이터가 있으면 캐시에서 불러오기
        if SearchViewModel.hasLoadedData {
            self.discoverItems = SearchViewModel.cachedDiscoverItems
            self.trendingItems = SearchViewModel.cachedTrendingItems
            self.newReleaseItems = SearchViewModel.cachedNewReleaseItems
            return
        }

        // 처음 로드하는 경우 API 호출
        await discoverViewModel?.load()
        await trendingViewModel?.load()
        await newReleasesViewModel?.load()

        // 캐시에 저장
        SearchViewModel.cachedDiscoverItems = self.discoverItems
        SearchViewModel.cachedTrendingItems = self.trendingItems
        SearchViewModel.cachedNewReleaseItems = self.newReleaseItems
        SearchViewModel.hasLoadedData = true
    }

    /// 강제로 새로고침 (pull-to-refresh용)
    func forceRefreshAllGames() async {
        SearchViewModel.hasLoadedData = false
        await discoverViewModel?.load()
        await trendingViewModel?.load()
        await newReleasesViewModel?.load()

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

    private func loadNextAll() async {
        await discoverViewModel?.loadNextPage()
        await trendingViewModel?.loadNextPage()
        await newReleasesViewModel?.loadNextPage()
    }
}
