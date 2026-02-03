//
//  SearchContentSection.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/27/26.
//
//  [신규] SearchView에서 분리된 컨텐츠 섹션 컴포넌트

import SwiftUI

// MARK: - Search Content Section

/// 검색 화면의 게임 목록 컨텐츠 섹션 컴포넌트입니다.
///
/// - Responsibilities:
///     - 로딩 상태에 따른 UI 표시 (로딩, 에러, 빈 상태, 결과)
///     - 2열 그리드 형태의 게임 카드 목록 표시
///     - 무한 스크롤을 위한 페이지네이션 처리
///
/// - Parameters:
///     - viewModel: `SearchViewModel` 인스턴스
///     - searchText: 현재 검색어
///     - selectedPlatform: 선택된 플랫폼 필터
///     - selectedGenre: 선택된 장르 필터
///     - advancedFilterState: 고급 필터 상태
///     - isSearchActive: 검색 활성화 상태
struct SearchContentSection: View {
    @ObservedObject var viewModel: SearchViewModel
    let searchText: String
    let selectedPlatform: PlatformFilterType
    let selectedGenre: GenreFilterType
    let advancedFilterState: AdvancedFilterState
    let isSearchActive: Bool

    // MARK: - Computed Properties

    private var isRemoteSearchActive: Bool {
        viewModel.isRemoteSearchActive(searchText: searchText)
    }

    private var isInitialLoading: Bool {
        if isRemoteSearchActive {
            return viewModel.isSearching && viewModel.filteredItems.isEmpty
        }
        // [수정] 장르 로딩 상태도 포함
        if selectedGenre != .all {
            return viewModel.isGenreLoading && viewModel.filteredItems.isEmpty
        }
        return viewModel.isLoading && viewModel.filteredItems.isEmpty
    }

    private var currentError: Error? {
        // [리팩토링] 통합된 error 속성 사용
        return viewModel.error
    }

    private var isLoadingMoreVisible: Bool {
        // [리팩토링] 통합된 isLoadingMore 속성 사용
        return viewModel.isLoadingMore
    }

    private var headerTitle: String {
        viewModel.headerTitle(platform: selectedPlatform, genre: selectedGenre)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 스크롤 상단 앵커
                Color.clear
                    .frame(height: 1)
                    .id("top")

                // 컨텐츠 상태에 따른 뷰 표시
                contentView
            }
            .padding(.bottom, 10)
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var contentView: some View {
        if isInitialLoading {
            LoadingView()
        } else if let error = currentError, viewModel.filteredItems.isEmpty {
            errorView(error: error)
        } else if isSearchActive && !isRemoteSearchActive {
            // [수정] 검색바 활성화 + 검색어 미입력 시 안내 문구 표시
            EmptyStateView.searchPrompt
        } else {
            resultsView
        }
    }

    private func errorView(error: Error) -> some View {
        ErrorView(error: error) {
            Task {
                if isRemoteSearchActive {
                    await viewModel.performSearch(query: searchText)
                } else {
                    await viewModel.loadAllGames()
                }
            }
        }
    }

    @ViewBuilder
    private var resultsView: some View {
        // 결과 헤더
        ResultHeader(
            title: headerTitle,
            count: viewModel.filteredItems.count
        )

        // 2열 그리드 게임 카드
        if viewModel.filteredItems.isEmpty {
            EmptyStateView.noSearchResults(
                platform: selectedPlatform,
                genre: selectedGenre
            )
        } else {
            gameGridView
        }
    }

    private var gameGridView: some View {
        VStack(spacing: 0) {
            GameGridView(items: viewModel.filteredItems) {
                // [리팩토링] 통합된 loadNextPage() 메서드 사용
                Task {
                    await viewModel.loadNextPage()
                }
            }

            if isLoadingMoreVisible {
                loadingMoreIndicator
            }
        }
    }

    private var loadingMoreIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.vertical, 12)
            Spacer()
        }
    }
}

// MARK: - Preview
struct SearchContentSection_Previews: PreviewProvider {
    static let favoriteManager = FavoriteManager()

    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            SearchContentSection(
                viewModel: SearchViewModel(favoriteManager: favoriteManager),
                searchText: "",
                selectedPlatform: .all,
                selectedGenre: .all,
                advancedFilterState: AdvancedFilterState(),
                isSearchActive: false
            )
        }
        .environmentObject(favoriteManager)
    }
}
