//
//  BookMarkOverlay.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//
//  [수정] Game 변환 제거 → GameListItem 직접 사용

import SwiftUI

// MARK: - View

/// 게임 카드 상단에 오버레이로 표시되는 부가 UI입니다.
///
/// 평점 배지와 즐겨찾기(북마크) 토글 버튼을 한 줄로 배치합니다.
struct BookMarkOverlay: View {
    let item: GameListItem
    /// 즐겨찾기(북마크) 상태를 관리하는 매니저입니다.
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
