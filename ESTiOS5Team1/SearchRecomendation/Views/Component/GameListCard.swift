//
//  GameListCard.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/15/26.
//
//  [통일] SearchView의 CompactGameCard와 LibraryView의 LibraryGameCard를 통일한 공통 게임 카드
//  [수정] Game → GameListItem 통일

import SwiftUI

// MARK: - Game List Card (통일된 게임 카드)
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
                        AsyncImage(url: coverURL) { phase in
                            switch phase {
                            case .empty:
                                GameListCardPlaceholder()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: 225)
                            case .failure:
                                GameListCardPlaceholder()
                            @unknown default:
                                GameListCardPlaceholder()
                            }
                        }
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
