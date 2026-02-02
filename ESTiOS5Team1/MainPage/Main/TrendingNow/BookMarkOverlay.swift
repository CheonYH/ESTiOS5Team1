//
//  BookMarkOverlay.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//
//  [수정] Game 변환 제거 → GameListItem 직접 사용

import SwiftUI

struct BookMarkOverlay: View {
    let item: GameListItem
    @EnvironmentObject var favoriteManager: FavoriteManager
    var needText: Bool = true
    var body: some View {
        HStack {
            // GameRatingBadge 통일 컴포넌트 사용
            if needText {
                GameRatingBadge(ratingText: item.ratingText)
            }
            
            Spacer()

            // [수정] GameListItem 직접 사용 - Game 변환 제거
            GameFavoriteButton(
                isFavorite: favoriteManager.isFavorite(itemId: item.id),
                onToggle: { favoriteManager.toggleFavorite(item: item) }
            )
        }
        .padding(4)
    }
}
