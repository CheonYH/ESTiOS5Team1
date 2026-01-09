//
//  SearchViewModel.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//

import Foundation
import Combine

/// SearchView를 위한 통합 ViewModel
/// 여러 카테고리의 게임 데이터를 관리
@MainActor
final class SearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var discoverGames: [Game] = []
    @Published var trendingGames: [Game] = []
    @Published var newReleaseGames: [Game] = []
    
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    private let service: IGDBService
    private let favoriteManager: FavoriteManager
    
    // 각 카테고리별 ViewModel
    private var discoverViewModel: GameListViewModel?
    private var trendingViewModel: GameListViewModel?
    private var newReleasesViewModel: GameListViewModel?
    
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
        discoverViewModel = GameListViewModel(
            service: service,
            query: IGDBQuery.discover
        )
        
        // Trending용 ViewModel
        trendingViewModel = GameListViewModel(
            service: service,
            query: IGDBQuery.trendingNow
        )
        
        // New Releases용 ViewModel
        newReleasesViewModel = GameListViewModel(
            service: service,
            query: IGDBQuery.newReleases
        )
        
        // ViewModel의 변화를 구독
        observeViewModels()
    }
    
    private func observeViewModels() {
        // Discover 데이터 변화 감지
        discoverViewModel?.$items
            .sink { [weak self] items in
                self?.discoverGames = items.map { Game(from: $0) }
                self?.favoriteManager.updateGames(self?.discoverGames ?? [])
            }
            .store(in: &cancellables)

        // Trending 데이터 변화 감지
        trendingViewModel?.$items
            .sink { [weak self] items in
                self?.trendingGames = items.map { Game(from: $0) }
                self?.favoriteManager.updateGames(self?.trendingGames ?? [])
            }
            .store(in: &cancellables)

        // New Releases 데이터 변화 감지
        newReleasesViewModel?.$items
            .sink { [weak self] items in
                self?.newReleaseGames = items.map { Game(from: $0) }
                self?.favoriteManager.updateGames(self?.newReleaseGames ?? [])
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
    func loadAllGames() {
        discoverViewModel?.loadGames()
        trendingViewModel?.loadGames()
        newReleasesViewModel?.loadGames()
    }
    
    /// 특정 카테고리만 새로고침
    func refreshDiscover() {
        discoverViewModel?.loadGames()
    }
    
    func refreshTrending() {
        trendingViewModel?.loadGames()
    }
    
    func refreshNewReleases() {
        newReleasesViewModel?.loadGames()
    }
}
