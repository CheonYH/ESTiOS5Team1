//
//  SearchView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
//  [수정] Game → GameListItem 통일
//  [수정] View 컴포넌트 분리 및 필터링 로직 ViewModel 이동

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

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    // 헤더 섹션
                    SearchHeaderSection(
                        isSearchActive: $isSearchActive,
                        searchText: $searchText,
                        onSearchSubmit: {
                            Task { await viewModel.performSearch(query: searchText) }
                        }
                    )

                    // 필터 섹션
                    SearchFilterSection(
                        selectedPlatform: $selectedPlatform,
                        selectedGenre: $selectedGenre,
                        advancedFilterState: $advancedFilterState,
                        showFilterSheet: $showFilterSheet,
                        allItems: viewModel.allItems
                    )

                    // 컨텐츠 섹션
                    SearchContentSection(
                        viewModel: viewModel,
                        searchText: searchText,
                        selectedPlatform: selectedPlatform,
                        selectedGenre: selectedGenre,
                        advancedFilterState: advancedFilterState,
                        isSearchActive: isSearchActive
                    )
                    .refreshable {
                        await viewModel.forceRefreshAllGames()
                    }
                    // 필터 변경 시 상단으로 스크롤
                    .onChange(of: selectedPlatform) { _ in
                        proxy.scrollTo("top", anchor: .top)
                    }
                    .onChange(of: selectedGenre) { _ in
                        proxy.scrollTo("top", anchor: .top)
                    }
                    .onChange(of: advancedFilterState) { _ in
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
        // [수정] 중복 onAppear 통합
        .onAppear {
            handleOnAppear()
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(filterState: $advancedFilterState)
        }
        .onChange(of: openSearchRequested) { v in
            guard v else { return }
            withAnimation(.spring(response: 0.3)) {
                isSearchActive = true
            }
            openSearchRequested = false
        }
        .onChange(of: searchText) { newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                viewModel.clearSearchResults()
            }
        }
        // 필터 변경 시 ViewModel에 적용
        .onChange(of: selectedPlatform) { _ in applyFilters() }
        .onChange(of: selectedGenre) { _ in applyFilters() }
        .onChange(of: searchText) { _ in applyFilters() }
        .onChange(of: advancedFilterState) { _ in applyFilters() }
        .onChange(of: viewModel.discoverItems) { _ in applyFilters() }
        .onChange(of: viewModel.trendingItems) { _ in applyFilters() }
        .onChange(of: viewModel.newReleaseItems) { _ in applyFilters() }
        .onChange(of: viewModel.searchItems) { _ in applyFilters() }
    }

    // MARK: - Private Methods

    /// [수정] 중복 onAppear 통합 - 데이터 로드 + 홈화면 검색 요청 처리
    private func handleOnAppear() {
        // 데이터 로드
        if viewModel.discoverItems.isEmpty {
            Task { await viewModel.loadAllGames() }
        }
        // 홈화면에서 검색 요청 시 처리
        if openSearchRequested {
            isSearchActive = true
            openSearchRequested = false
        }
        // 초기 필터 적용
        applyFilters()
    }

    /// 필터 적용
    private func applyFilters() {
        viewModel.applyFilters(
            platform: selectedPlatform,
            genre: selectedGenre,
            searchText: searchText,
            advancedFilter: advancedFilterState
        )
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
