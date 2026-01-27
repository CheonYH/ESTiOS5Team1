//
//  SearchContentSection.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/27/26.
//
//  [신규] SearchView에서 분리된 컨텐츠 섹션 컴포넌트

import SwiftUI

/// 검색 화면의 컨텐츠 섹션 (게임 목록)
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
            return viewModel.isSearching && viewModel.searchItems.isEmpty
        }
        // [수정] 장르 로딩 상태도 포함
        if selectedGenre != .all {
            return viewModel.isGenreLoading && viewModel.genreItems.isEmpty
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
        // [수정] 장르 로딩 상태도 포함
        if selectedGenre != .all {
            return viewModel.isGenreLoadingMore
        }
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
                Task {
                    if isRemoteSearchActive {
                        await viewModel.loadNextSearchPage()
                    } else {
                        await viewModel.loadNext(for: advancedFilterState.category)
                    }
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
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            SearchContentSection(
                viewModel: SearchViewModel(favoriteManager: FavoriteManager()),
                searchText: "",
                selectedPlatform: .all,
                selectedGenre: .all,
                advancedFilterState: AdvancedFilterState(),
                isSearchActive: false
            )
        }
    }
}
