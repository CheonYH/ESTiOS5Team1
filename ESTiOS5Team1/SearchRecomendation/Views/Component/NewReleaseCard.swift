//
//  NewReleaseCard.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//


import SwiftUI

// MARK: - New Release Card
struct NewReleaseCard: View {
    let game: Game
    @EnvironmentObject var favoriteManager: FavoriteManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Game Image
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 140)
                    .cornerRadius(12)
                
                // Heart Button on Image
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
                .padding(8)
            }
            
            // Game Info
            VStack(alignment: .leading, spacing: 8) {
                Text(game.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(game.genre + " • " + game.releaseYear)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Rating and Platforms
                HStack(spacing: 8) {
                    // Rating
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
                    
                    // Platform Icons
                    HStack(spacing: 4) {
                        ForEach(game.platforms, id: \.rawValue) { platform in
                            Image(systemName: "gamecontroller.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
            }
            
            Spacer()
            
            // Add Button
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.purple)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}