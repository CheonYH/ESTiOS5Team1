//
//  BookMarkOverlay.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI

struct BookMarkOverlay: View {
    let item: GameListItem
    // [수정] @State 제거 → FavoriteManager 연동
    @EnvironmentObject var favoriteManager: FavoriteManager

    // [수정] GameListItem을 Game으로 변환
    private var game: Game {
        Game(from: item)
    }

    var body: some View {
        HStack {
            RatingText(item: item)

            Spacer()

            // [수정] FavoriteManager와 연동된 하트 버튼 + UI 통일
            Button {
                favoriteManager.toggleFavorite(game: game)
            } label: {
                Image(systemName: favoriteManager.isFavorite(gameId: game.id) ? "heart.fill" : "heart")
                    .font(.system(size: 14))
                    .foregroundColor(favoriteManager.isFavorite(gameId: game.id) ? .red : .white)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())  // [수정] 버튼 터치 문제 해결
        }
        .padding(4)
    }
}
