//
//  LibraryView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
//  [수정] Game → GameListItem 통일

import SwiftUI

// MARK: - Library View
struct LibraryView: View {
    @EnvironmentObject var favoriteManager: FavoriteManager
    @State private var isSearchActive = false
    @State private var searchText = ""
    @State private var showRoot = false
    @EnvironmentObject var tabBarState: TabBarState
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // [수정] 검색 필터링된 게임 목록 - Game → GameListItem
    var filteredItems: [GameListItem] {
        if searchText.isEmpty {
            return favoriteManager.favoriteItems
        } else {
            return favoriteManager.favoriteItems.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.genre.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        // [수정] NavigationStack 제거 - MainTabView의 NavigationStack 사용
        // 커스텀 헤더로 대체하여 중첩 문제 해결
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // 커스텀 헤더
                CustomNavigationHeader(
                    title: "내 게임",
                    showSearchButton: true,
                    isSearchActive: isSearchActive,
                    onSearchTap: {
                        withAnimation(.spring(response: 0.3)) {
                            isSearchActive.toggle()
                            if !isSearchActive {
                                searchText = ""
                            }
                        }
                    },
                    showRoot: $showRoot
                )

                // 검색바 (조건부 표시)
                if isSearchActive {
                    SearchBar(
                        searchText: $searchText,
                        isSearchActive: $isSearchActive,
                        placeholder: "게임 제목 또는 장르로 검색..."
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 게임 목록
                ScrollView {
                    // [수정] favoriteGames → favoriteItems
                    // [수정] EmptyStateView 공통 컴포넌트 사용
                    if favoriteManager.favoriteItems.isEmpty {
                        EmptyStateView.emptyLibrary
                    } else if filteredItems.isEmpty {
                        // 검색 결과 없음
                        EmptyStateView.noLibrarySearchResults
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            // [수정] game → item
                            // [수정] NavigationLink 추가하여 DetailView로 이동
                            ForEach(filteredItems) { item in
                                NavigationLink(destination: DetailView(gameId: item.id)) {
                                    GameListCard(
                                        item: item,
                                        isFavorite: favoriteManager.isFavorite(itemId: item.id),
                                        onToggleFavorite: {
                                            favoriteManager.toggleFavorite(item: item)
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationDestination(isPresented: $showRoot) {
                RootTabView()
                    .onAppear { tabBarState.isHidden = true }
                    .onDisappear { tabBarState.isHidden = false }
            }
            .onAppear { tabBarState.isHidden = false }
        }
    }
}

// MARK: - Preview
struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .environmentObject(FavoriteManager())
    }
}
