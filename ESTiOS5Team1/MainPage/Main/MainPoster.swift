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
            KFImage(item.coverURL)
                .cacheOriginalImage()
                .loadDiskFileSynchronously()
                .placeholder { Color.gray.opacity(0.3) }
                .resizable()
                .scaledToFill()
                .frame(height: 400)
                .clipped()
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("FEATURED")
                        .font(.callout)
                        .foregroundStyle(.textPrimary)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(.purple, in: Capsule())

                    Text(item.ratingText)// 임시
                        .font(.callout)
                        .foregroundStyle(.textPrimary)
                        .bold()
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(.yellow, in: Capsule())
                }

                Text(item.title)
                    .font(.largeTitle)
                    .foregroundStyle(.textPrimary)

//                Text(item.id.description ?? "")
//                    .font(.caption)
//                    .foregroundStyle(.textPrimary)
//                    .multilineTextAlignment(.leading)

                Text(item.genre.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundColor(.textPrimary.opacity(0.7))

                ForEach(item.platformCategories, id: \.rawValue) { platform in
                    Image(systemName: platform.iconName)
                        .foregroundStyle(.textPrimary.opacity(0.6))
                        .font(.caption)
                }

                HStack {
                    Button {
                        // 플레이 나우 기능
                    } label: {
                        Label("Play Now", systemImage: "play.fill")
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
