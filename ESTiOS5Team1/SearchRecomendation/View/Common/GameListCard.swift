//
//  GameListCard.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/15/26.
//
//  [통일] SearchView의 CompactGameCard와 LibraryView의 LibraryGameCard를 통일한 공통 게임 카드
//  [수정] Game → GameListItem 통일

import SwiftUI
import Kingfisher

// MARK: - Game List Card

/// 게임 목록에서 사용하는 통일된 게임 카드 컴포넌트입니다.
struct GameListCard: View {
    // [수정] Game → GameListItem
    let item: GameListItem
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 게임 이미지
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // 커버 이미지
                    if let coverURL = item.coverURL {
                        KFImage(coverURL)
                            .cacheOriginalImage()
                            .loadDiskFileSynchronously()
                            .placeholder {
                                GameListCardPlaceholder()
                            }
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: 225)
                    } else {
                        GameListCardPlaceholder()
                    }

                    // 평점 배지 (왼쪽 상단) - GameRatingBadge 사용
                    GameRatingBadge(ratingText: item.ratingText)
                        .padding(8)

                    // 즐겨찾기 버튼 (오른쪽 상단) - GameFavoriteButton 사용
                    VStack {
                        HStack {
                            Spacer()
                            GameFavoriteButton(isFavorite: isFavorite, onToggle: onToggleFavorite)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
                .frame(width: geometry.size.width, height: 225)
                .clipped()
            }
            .frame(height: 225)
            .cornerRadius(12)
            .clipped()

            // 게임 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                // [수정] genre가 배열이므로 joined 사용
                Text(item.genre.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)

                // [수정] platforms → platformCategories
                HStack(spacing: 4) {
                    ForEach(item.platformCategories.prefix(3), id: \.rawValue) { platform in
                        Image(systemName: platform.iconName)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    if item.platformCategories.count > 3 {
                        Text("+\(item.platformCategories.count - 3)")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .background(Color.clear)
    }
}

// MARK: - Game List Card Placeholder

/// 게임 이미지 로딩 중 또는 이미지가 없을 때 표시되는 플레이스홀더입니다.
struct GameListCardPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(height: 225)
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("이미지 준비중입니다")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
    }
}
