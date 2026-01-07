//
//  LibraryView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//

import SwiftUI

// MARK: - Library View
struct LibraryView: View {
    @EnvironmentObject var favoriteManager: FavoriteManager

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    if favoriteManager.favoriteGames.isEmpty {
                        emptyStateView
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(favoriteManager.favoriteGames) { game in
                                LibraryGameCard(game: game)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundColor(.purple)
                        Text("GameVault")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                Text("Library")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.leading, 20)
                    .padding(.top, 60)
            }
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("저장된 게임이 없습니다")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("게임 카드의 하트 아이콘을 눌러\n마음에 드는 게임을 저장하세요")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Library Game Card
struct LibraryGameCard: View {
    let game: Game
    @EnvironmentObject var favoriteManager: FavoriteManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Game Image
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 240)
                    .cornerRadius(12)

                // Rating Badge and Heart Button
                HStack {
                    // Rating Badge
                    if game.rating > 0 {
                        Text(String(format: "%.1f", game.rating))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .cornerRadius(6)
                    }

                    Spacer()

                    // Heart Button
                    Button(action: {
                        favoriteManager.toggleFavorite(game: game)
                    }) {
                        Image(systemName: favoriteManager.isFavorite(gameId: game.id) ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                }
                .padding(8)
            }

            // Game Info
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(height: 36, alignment: .top)

                Text(game.genre)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
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
