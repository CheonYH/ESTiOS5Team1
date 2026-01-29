//
//  GameCardOverlay.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/16/26.
//
//  [통일] 게임 카드 오버레이 컴포넌트 - 별점 배지 & 즐겨찾기 버튼

import SwiftUI

// MARK: - Game Rating Badge (별점 배지)
struct GameRatingBadge: View {
    let ratingText: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
            Text(ratingText)
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.black)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.yellow)
        .cornerRadius(8)
    }
}

// MARK: - Game Favorite Button (즐겨찾기 하트 버튼)
struct GameFavoriteButton: View {
    let isFavorite: Bool
    let onToggle: () -> Void
    var frameWH: CGFloat = 32

    var body: some View {
        Button(action: onToggle) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 14))
                .foregroundColor(isFavorite ? .red : .white)
                .frame(width: frameWH, height: frameWH)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview("GameCardOverlay Components") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 30) {
            // Rating Badge
            VStack {
                Text("Rating Badge")
                    .foregroundColor(.gray)
                HStack(spacing: 12) {
                    GameRatingBadge(ratingText: "8.9")
                    GameRatingBadge(ratingText: "N/A")
                }
            }

            // Favorite Button
            VStack {
                Text("Favorite Button")
                    .foregroundColor(.gray)
                HStack(spacing: 12) {
                    GameFavoriteButton(isFavorite: false) {}
                    GameFavoriteButton(isFavorite: true) {}
                }
            }
        }
    }
}
