//
//  SearchView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
//  [수정] Game → GameListItem 통일

import SwiftUI

// MARK: - Search View
struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedPlatform: PlatformFilterType
    @State private var selectedGenre: GenreFilterType
    @State private var isSearchActive = false

    // 고급 필터 상태
    @State private var advancedFilterState = AdvancedFilterState()
    @State private var showFilterSheet = false

    @StateObject private var viewModel: SearchViewModel
    @EnvironmentObject var favoriteManager: FavoriteManager
    
    @Binding var openSearchRequested: Bool
    // MARK: - Initialization

    /// 통합 Initializer (기본값으로 3개 init 통합)
    /// - Parameters:
    ///   - favoriteManager: 즐겨찾기 관리자
    ///   - initialGenre: 초기 장르 필터 (기본값: .all)
    ///   - initialPlatform: 초기 플랫폼 필터 (기본값: .all)
    init(
        favoriteManager: FavoriteManager,
        initialGenre: GenreFilterType = .all,
        initialPlatform: PlatformFilterType = .all,
        openSearchRequested: Binding<Bool> = .constant(false)
    ) {
        self._openSearchRequested = openSearchRequested
        _viewModel = StateObject(wrappedValue: SearchViewModel(favoriteManager: favoriteManager))
        _selectedPlatform = State(initialValue: initialPlatform)
        _selectedGenre = State(initialValue: initialGenre)
    }

    /// GameGenreModel을 사용하는 편의 Initializer (홈 화면 장르 버튼에서 사용)
    init(favoriteManager: FavoriteManager, gameGenre: GameGenreModel, openSearchRequested: Binding<Bool> = .constant(false)) {
        self._openSearchRequested = openSearchRequested
        _viewModel = StateObject(wrappedValue: SearchViewModel(favoriteManager: favoriteManager))
        _selectedPlatform = State(initialValue: .all)
        _selectedGenre = State(initialValue: GenreFilterType.from(gameGenre: gameGenre))
    }

    var body: some View {
        // [수정] NavigationStack 제거 - MainTabView의 NavigationStack 사용
        // 커스텀 헤더로 대체하여 중첩 문제 해결
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    // 커스텀 헤더
                    CustomNavigationHeader(
                        title: "게임 탐색",
                        showSearchButton: true,
                        isSearchActive: isSearchActive,
                        onSearchTap: {
                            withAnimation(.spring(response: 0.3)) {
                                isSearchActive.toggle()
                                if !isSearchActive {
                                    searchText = ""
                                }
                            }
                        }
                    )

                    // 검색바 (조건부 표시)
                    if isSearchActive {
                        SearchBar(searchText: $searchText, isSearchActive: $isSearchActive) {
                            Task {
                                await viewModel.performSearch(query: searchText)
                            }
                        }
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Platform Filter (고정)
                    PlatformFilter(selectedPlatform: $selectedPlatform)
                        .padding(.top, 10)

                    // Genre Filter (고정, 하단 구분선 포함)
                    GenreFilter(selectedGenre: $selectedGenre, items: allItems)
                        .padding(.top, 10)

                    // 고급 필터 버튼 바 (필터 버튼 + 선택된 필터 캡슐)
                    FilterButtonBar(
                        filterState: $advancedFilterState,
                        showFilterSheet: $showFilterSheet
                    )

                    // 게임 카드만 스크롤
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            // 스크롤 상단 앵커
                            Color.clear
                                .frame(height: 1)
                                .id("top")

                            // 로딩 또는 에러 상태
                            if isInitialLoading {
                                LoadingView()
                            } else if let error = currentError, filteredItems.isEmpty {
                                ErrorView(error: error) {
                                    Task {
                                        if isRemoteSearchActive {
                                            await viewModel.performSearch(query: searchText)
                                        } else {
                                            await viewModel.loadAllGames()
                                        }
                                    }
                                }
                            } else if isSearchActive && !isRemoteSearchActive {
                                EmptyView()
                            } else {
                                // 결과 헤더
                                ResultHeader(
                                    title: headerTitle,
                                    count: filteredItems.count
                                )

                                // 2열 그리드 게임 카드
                                if filteredItems.isEmpty {
                                    EmptyStateView.noSearchResults(
                                        platform: selectedPlatform,
                                        genre: selectedGenre
                                    )
                                } else {
                                    GameGridView(items: filteredItems) {
                                        Task {
                                            if isRemoteSearchActive {
                                                await viewModel.loadNextSearchPage()
                                            } else {
                                                await viewModel.loadNext(for: advancedFilterState.category)
                                            }
                                        }
                                    }
                                    if isLoadingMoreVisible {
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                                .padding(.vertical, 12)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    .refreshable {
                        await viewModel.forceRefreshAllGames()
                    }
                    // 플랫폼 변경 시 상단으로 스크롤
                    .onChange(of: selectedPlatform) { _ in
                        proxy.scrollTo("top", anchor: .top)
                    }
                    // 장르 변경 시 상단으로 스크롤
                    .onChange(of: selectedGenre) { _ in
                        proxy.scrollTo("top", anchor: .top)
                    }
                    // 고급 필터 변경 시 상단으로 스크롤
                    .onChange(of: advancedFilterState) { _ in
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
        // [수정] discoverGames → discoverItems
        .onAppear {
            if viewModel.discoverItems.isEmpty {
                Task { await viewModel.loadAllGames() }
            }
        }
        // 필터 시트 표시
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(filterState: $advancedFilterState)
        }
        .onChange(of: openSearchRequested) { v in
            guard v else { return }
            withAnimation(.spring(response: 0.3)) {
                isSearchActive = true
            }
            openSearchRequested = false // 한번 열었으면 리셋
        }
        .onChange(of: searchText) { newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                viewModel.clearSearchResults()
            }
        }
        .onAppear {
            // 첫 렌더에서 이미 true로 들어온 경우 보정
            if openSearchRequested {
                isSearchActive = true
                openSearchRequested = false
            }
        }
    }
    

    // MARK: - Computed Properties

    private var hasActiveFilters: Bool {
        selectedPlatform != .all || selectedGenre != .all || !searchText.isEmpty
    }

    private var isRemoteSearchActive: Bool {
        !viewModel.lastSearchQuery.isEmpty && viewModel.lastSearchQuery == searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isInitialLoading: Bool {
        if isRemoteSearchActive {
            return viewModel.isSearching && viewModel.searchItems.isEmpty
        }
        return viewModel.isLoading && viewModel.discoverItems.isEmpty
    }

    private var currentError: Error? {
        if isRemoteSearchActive {
            return viewModel.searchError
        }
        return viewModel.error
    }

    private var isLoadingMoreVisible: Bool {
        if isRemoteSearchActive {
            return viewModel.isSearchLoadingMore
        }
        return viewModel.isLoadingMore
    }

    private var headerTitle: String {
        var components: [String] = []

        if selectedPlatform != .all {
            components.append(selectedPlatform.rawValue)
        }

        if selectedGenre != .all {
            components.append(selectedGenre.displayName)
        }

        if components.isEmpty {
            return "추천 게임"
        }

        return components.joined(separator: " · ") + " 게임"
    }

    // [수정] 모든 게임 (중복 제거, 순서 유지) - Game → GameListItem
    // 카테고리 필터 적용
    private var allItems: [GameListItem] {
        if isRemoteSearchActive {
            return viewModel.searchItems
        }
        // 카테고리에 따라 데이터 소스 선택
        let items: [GameListItem]
        switch advancedFilterState.category {
        case .all:
            items = viewModel.discoverItems + viewModel.trendingItems + viewModel.newReleaseItems
        case .trending:
            items = viewModel.trendingItems
        case .newReleases:
            items = viewModel.newReleaseItems
        case .discover:
            items = viewModel.discoverItems
        }

        // 중복 제거
        var seen = Set<Int>()
        return items.filter { item in
            if seen.contains(item.id) { return false }
            seen.insert(item.id)
            return true
        }
    }

    // [수정] filteredGames → filteredItems
    // 모든 필터 적용 (플랫폼, 장르, 검색어, 고급 필터)
    private var filteredItems: [GameListItem] {
        var result = allItems.filter { item in
            let matchesPlatform = filterByPlatform(item: item, platform: selectedPlatform)
            let matchesGenre = filterByGenre(item: item, genre: selectedGenre)
            let matchesSearch = isRemoteSearchActive
                ? true
                : (searchText.isEmpty ||
                    item.title.localizedCaseInsensitiveContains(searchText) ||
                    item.genre.joined(separator: " ").localizedCaseInsensitiveContains(searchText))

            // 평점 필터
            let matchesRating = filterByRating(item: item)

            // 출시 시기 필터
            let matchesReleasePeriod = advancedFilterState.releasePeriod.matches(releaseYear: item.releaseYearText)

            return matchesPlatform && matchesGenre && matchesSearch && matchesRating && matchesReleasePeriod
        }

        // 정렬 적용
        result = sortItems(result)

        return result
    }

    // MARK: - Advanced Filter Methods

    /// 평점 필터 적용 (슬라이더 기반)
    private func filterByRating(item: GameListItem) -> Bool {
        // 최소 평점이 0이면 모든 게임 표시
        guard advancedFilterState.minimumRating > 0 else { return true }

        // ratingText를 Double로 변환 (예: "4.2" -> 4.2)
        guard item.ratingText != "N/A",
              let rating = Double(item.ratingText) else {
            // 평점이 없는 경우 필터링에서 제외
            return false
        }

        return rating >= advancedFilterState.minimumRating
    }

    /// 정렬 적용
    private func sortItems(_ items: [GameListItem]) -> [GameListItem] {
        switch advancedFilterState.sortType {
        case .popularity:
            // 기본 순서 유지 (API에서 이미 인기순으로 정렬됨)
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

    // MARK: - Helper Methods

    // [수정] PlatformFilterType.matches() 메서드 사용으로 단순화
    private func filterByPlatform(item: GameListItem, platform: PlatformFilterType) -> Bool {
        guard platform != .all else { return true }
        return item.platformCategories.contains { platform.matches($0) }
    }

    // [수정] game → item, genre가 배열이므로 any로 매칭
    private func filterByGenre(item: GameListItem, genre: GenreFilterType) -> Bool {
        guard genre != .all else { return true }
        return item.genre.contains { genreString in
            genre.matches(genre: genreString)
        }
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SearchView(favoriteManager: FavoriteManager())
                .environmentObject(FavoriteManager())
                .previewDisplayName("기본")

            SearchView(favoriteManager: FavoriteManager(), initialGenre: .shooter)
                .environmentObject(FavoriteManager())
                .previewDisplayName("장르 선택됨")
        }
    }
}
