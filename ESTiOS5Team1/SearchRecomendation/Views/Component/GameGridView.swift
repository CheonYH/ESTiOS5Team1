//
//  GameGridView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
//  2열 그리드 게임 카드 컴포넌트 - SearchView, LibraryView에서 재사용

import SwiftUI

// MARK: - Game Grid View (2열 세로 스크롤)
struct GameGridView: View {
    let items: [GameListItem]
    @EnvironmentObject var favoriteManager: FavoriteManager

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items, id: \.id) { item in
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
        .animation(nil, value: items.map { $0.id })
    }
}
