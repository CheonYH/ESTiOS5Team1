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

    // MARK: - Published Properties
    // [수정] Game → GameListItem
    @Published var discoverItems: [GameListItem] = []
    @Published var trendingItems: [GameListItem] = []
    @Published var newReleaseItems: [GameListItem] = []

    @Published var isLoading: Bool = false
    @Published var error: Error?

    // MARK: - Private Properties
    private let service: IGDBService
    private let favoriteManager: FavoriteManager

    // 각 카테고리별 ViewModel
    private var discoverViewModel: GameListSingleQueryViewModel?
    private var trendingViewModel: GameListSingleQueryViewModel?
    private var newReleasesViewModel: GameListSingleQueryViewModel?

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

    /// 모든 카테고리 데이터 로드
    func loadAllGames() async {
        await discoverViewModel?.load()
        await trendingViewModel?.load()
        await newReleasesViewModel?.load()
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
}
