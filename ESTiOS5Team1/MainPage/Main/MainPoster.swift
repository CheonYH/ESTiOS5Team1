//
//  MainPoster.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI
import Kingfisher

struct MainPoster: View {
    let item: GameListItem
    @EnvironmentObject var favoriteManager: FavoriteManager

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let coverURL = item.coverURL {
                KFImage(coverURL)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 600, height: 333)))
                    .placeholder { GameListCardPlaceholder() }
                    .resizable()
                    .scaledToFill()
                    .frame(height: 400)
                    .clipped()
                    .padding(.top, 20)
            } else {
                GameListCardPlaceholder()
                    .frame(height: 400)
                    .padding(.top, 20)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("FEATURED")
                        .font(.callout)
                        .foregroundStyle(.textPrimary)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(.purple, in: Capsule())

                    GameRatingBadge(ratingText: item.ratingText)
                }

                Text(item.title)
                    .font(.title.bold())
                    .foregroundStyle(.textPrimary)
                    .shadow(color: .black.opacity(0.9), radius: 1, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.55), radius: 6, x: 0, y: 3)
                
                Text(item.genre.joined(separator: " · "))
                    .font(.callout)
                    .foregroundColor(.textPrimary)
                    .shadow(color: .black.opacity(0.9), radius: 1, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.55), radius: 6, x: 0, y: 3)
                
                ForEach(item.platformCategories, id: \.rawValue) { platform in
                    Image(systemName: platform.iconName)
                        .foregroundStyle(.textPrimary)
                        .font(.callout).shadow(color: .black.opacity(0.9), radius: 1, x: 0, y: 1)
                        .shadow(color: .black.opacity(0.55), radius: 6, x: 0, y: 3)
                }

                HStack {
                    NavigationLink(destination: DetailView(gameId: item.id)) {
                        Label("게임 정보 확인", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundStyle(.textPrimary)
                            .frame(maxWidth: 250)
                            .frame(height: 40)
                            .background(.purple, in: RoundedRectangle(cornerRadius: Radius.cr16))
                    }
                    GameFavoriteButton(
                        isFavorite: favoriteManager.isFavorite(itemId: item.id),
                        onToggle: { favoriteManager.toggleFavorite(item: item) },
                        frameWH: 40
                    )
                }
            }
            .padding()
        }
    }
}
