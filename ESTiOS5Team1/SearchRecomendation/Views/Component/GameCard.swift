//
//  GameCard.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//


import SwiftUI

// MARK: - Game Card
struct GameCard: View {
    let game: Game
    @EnvironmentObject var favoriteManager: FavoriteManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                // Game Image
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 140, height: 200)
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
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                }
                .padding(8)
                .frame(width: 140, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(game.genre)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: 140)
        }
    }
}