//
//  GameListCard.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/15/26.
//
//  [통일] SearchView의 CompactGameCard와 LibraryView의 LibraryGameCard를 통일한 공통 게임 카드

import SwiftUI

// MARK: - Game List Card (통일된 게임 카드)
struct GameListCard: View {
    let game: Game
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 게임 이미지
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // 커버 이미지
                    if let coverURL = game.coverURL {
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

                    // 평점 배지 (왼쪽 상단)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text(game.ratingText)
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .cornerRadius(8)
                    .padding(8)

                    // 즐겨찾기 버튼 (오른쪽 상단)
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onToggleFavorite) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 14))
                                    .foregroundColor(isFavorite ? .red : .white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
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
                Text(game.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(game.genre)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)

                // 플랫폼 아이콘
                HStack(spacing: 4) {
                    ForEach(game.platforms.prefix(3), id: \.rawValue) { platform in
                        Image(systemName: platform.iconName)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    if game.platforms.count > 3 {
                        Text("+\(game.platforms.count - 3)")
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
