//
//  ComingSoonCard.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//

import SwiftUI

// MARK: - Coming Soon Card
struct ComingSoonCard: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Game Image
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 280, height: 350)
                    .cornerRadius(12)

                // Coming Soon Badge
                Text(game.releaseYear)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple)
                    .cornerRadius(8)
                    .padding(12)
            }

            // Game Info Overlay
            VStack(alignment: .leading, spacing: 8) {
                Text(game.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Image(systemName: "playstation.logo")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("TRA")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Platform Icons Row
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "house.fill")
                            .foregroundColor(.purple)
                    }

                    Button(action: {}) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.gray)
                    }

                    Button(action: {}) {
                        Image(systemName: "rectangle.stack.fill")
                            .foregroundColor(.gray)
                    }
                }
                .font(.title3)
            }
            .padding(16)
            .frame(width: 280)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .offset(y: -50)
        }
    }
}
