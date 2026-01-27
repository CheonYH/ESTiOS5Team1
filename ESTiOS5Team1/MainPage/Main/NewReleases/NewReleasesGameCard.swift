//
//  SwiftUIView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/9/26.
//

import SwiftUI
import Kingfisher

struct NewReleasesGameCard: View {
    let item: GameListItem
    @EnvironmentObject var favoriteManager: FavoriteManager

    var body: some View {
            HStack {
                KFImage(item.coverURL)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 160, height: 93)))
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(Radius.card)

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.title2)

                    Text(item.genre.joined(separator: " · "))
                        .font(.caption)
                        .foregroundColor(.textPrimary.opacity(0.7))

                    HStack {
                        RatingText(item: item)

                        ForEach(item.platformCategories, id: \.rawValue) { platform in
                            Image(systemName: platform.iconName)
                                .foregroundStyle(.textPrimary.opacity(0.6))
                                .font(.caption)
                        }

                        Spacer()

                        GameFavoriteButton(isFavorite: favoriteManager.isFavorite(itemId: item.id), onToggle: {
                            favoriteManager.toggleFavorite(item: item)
                        }, frameWH: 36)

                    }
                }
                .foregroundStyle(.textPrimary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(.textPrimary.opacity(0.12))
            )
        }
}
