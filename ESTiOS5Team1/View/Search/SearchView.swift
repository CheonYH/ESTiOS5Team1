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

/// 게임 검색 및 탐색을 위한 메인 화면입니다.
///
/// - Responsibilities:
///     - 검색바를 통한 게임 검색
///     - 플랫폼, 장르, 고급 필터를 통한 게임 필터링
///     - 2열 그리드 형태의 게임 목록 표시
///     - 무한 스크롤을 통한 추가 데이터 로드
///
/// - Important:
///     - `SearchViewModel`을 통해 비즈니스 로직을 처리합니다.
///     - `FavoriteManager`를 `@EnvironmentObject`로 주입받습니다.
///     - 홈 화면에서 장르 선택 시 `pendingGenre`를 통해 필터가 적용됩니다.
///
/// - Example:
///     ```swift
///     SearchView(favoriteManager: favoriteManager)
///         .environmentObject(favoriteManager)
///         .environmentObject(tabBarState)
///     ```
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
    @EnvironmentObject var tabBarState: TabBarState

    @Binding var openSearchRequested: Bool
    @Binding var pendingGenre: GameGenreModel?
    // [추가] 탭 전환 시 검색 상태 초기화용
    @Binding var shouldResetSearch: Bool

    // MARK: - Initialization

    /// SearchView를 초기화합니다.
    ///
    /// - Parameters:
    ///   - favoriteManager: 즐겨찾기 관리 매니저
    ///   - initialGenre: 초기 장르 필터 (기본값: `.all`)
    ///   - initialPlatform: 초기 플랫폼 필터 (기본값: `.all`)
    ///   - openSearchRequested: 검색 활성화 요청 바인딩
    ///   - pendingGenre: 대기 중인 장르 선택 바인딩 (홈에서 전달)
    ///   - shouldResetSearch: 검색 초기화 요청 바인딩 (탭 전환 시 사용)
    init(
        favoriteManager: FavoriteManager,
        initialGenre: GenreFilterType = .all,
        initialPlatform: PlatformFilterType = .all,
        openSearchRequested: Binding<Bool> = .constant(false),
        pendingGenre: Binding<GameGenreModel?> = .constant(nil),
        shouldResetSearch: Binding<Bool> = .constant(false)
    ) {
        self._openSearchRequested = openSearchRequested
        self._pendingGenre = pendingGenre
        self._shouldResetSearch = shouldResetSearch
        _viewModel = StateObject(wrappedValue: SearchViewModel(favoriteManager: favoriteManager))
        _selectedPlatform = State(initialValue: initialPlatform)
        _selectedGenre = State(initialValue: initialGenre)
    }

    /// `GameGenreModel`을 사용하는 편의 초기화 메서드입니다.
    ///
    /// - Parameters:
    ///   - favoriteManager: 즐겨찾기 관리 매니저
    ///   - gameGenre: 홈 화면에서 선택된 장르
    ///   - openSearchRequested: 검색 활성화 요청 바인딩
    ///   - pendingGenre: 대기 중인 장르 선택 바인딩
    ///   - shouldResetSearch: 검색 초기화 요청 바인딩
    ///
    /// - Note:
    ///     홈 화면의 장르 버튼 탭 시 사용됩니다.
    init(
        favoriteManager: FavoriteManager,
        gameGenre: GameGenreModel,
        openSearchRequested: Binding<Bool> = .constant(false),
        pendingGenre: Binding<GameGenreModel?> = .constant(nil),
        shouldResetSearch: Binding<Bool> = .constant(false)
    ) {
        self._openSearchRequested = openSearchRequested
        self._pendingGenre = pendingGenre
        self._shouldResetSearch = shouldResetSearch
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
                        await viewModel.forceRefresh()
                    }
                    // 필터 변경 시 상단으로 스크롤
                    .onChange(of: selectedPlatform) {
                        proxy.scrollTo("top", anchor: .top)
                    }
                    .onChange(of: selectedGenre) {
                        proxy.scrollTo("top", anchor: .top)
                    }
                    .onChange(of: advancedFilterState) {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
        // [수정] 중복 onAppear 통합
        .onAppear {
            handleOnAppear()
        }
        // [삭제] onDisappear 제거 - 디테일뷰 이동 시에도 호출되어 검색 초기화 문제 발생
        // 탭 전환 시 초기화는 shouldResetSearch 바인딩으로만 처리
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(filterState: $advancedFilterState)
        }
        .onChange(of: openSearchRequested) { _, value in
            guard value else { return }
            // [추가] 홈에서 검색 버튼 클릭 시 필터 초기화 (UX 개선)
            selectedPlatform = .all
            selectedGenre = .all
            withAnimation(.spring(response: 0.3)) {
                isSearchActive = true
            }
            openSearchRequested = false
        }
        .onChange(of: pendingGenre) { _, genre in
            guard let genre else { return }
            selectedGenre = GenreFilterType.from(gameGenre: genre)
            pendingGenre = nil
        }
        // [추가] 탭 전환 시 검색 상태 초기화 (실무 방식: 부모에서 신호 전달)
        .onChange(of: shouldResetSearch) { _, value in
            guard value else { return }
            isSearchActive = false
            searchText = ""
            viewModel.clearSearchResults()
            shouldResetSearch = false
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                viewModel.clearSearchResults()
            }
        }
        // 필터 변경 시 ViewModel에 적용
        .onChange(of: selectedPlatform) { _, _ in applyFilters() }
        .onChange(of: selectedGenre) { _, newGenre in
            // [추가] 장르 변경 시 서버에서 해당 장르 데이터 로드
            viewModel.prepareGenreLoading(newGenre)
            Task {
                await viewModel.loadGamesForGenre(newGenre)
            }
            applyFilters()
        }
        .onChange(of: searchText) { _, _ in applyFilters() }
        .onChange(of: advancedFilterState) { _, _ in applyFilters() }
        // [리팩토링] ViewModel 내부에서 자동 업데이트되므로 개별 데이터 관찰 불필요
    }

    // MARK: - Private Methods

    /// [수정] 중복 onAppear 통합 - 데이터 로드 + 홈화면 검색 요청 처리
    private func handleOnAppear() {
        // 데이터 로드
        if viewModel.allItems.isEmpty {
            Task { await viewModel.loadAllGames() }
        }
        // 홈화면에서 검색 요청 시 처리
        if openSearchRequested {
            isSearchActive = true
            openSearchRequested = false
        }

        if let genre = pendingGenre {
            selectedGenre = GenreFilterType.from(gameGenre: genre)
            pendingGenre = nil
        }

        tabBarState.isHidden = false
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
    static let favoriteManager = FavoriteManager()
    static let tabBarState = TabBarState()

    static var previews: some View {
        Group {
            SearchView(favoriteManager: favoriteManager)
                .environmentObject(favoriteManager)
                .environmentObject(tabBarState)
                .previewDisplayName("기본")

            SearchView(favoriteManager: favoriteManager, initialGenre: .shooter)
                .environmentObject(favoriteManager)
                .environmentObject(tabBarState)
                .previewDisplayName("장르 선택됨")
        }
    }
}
