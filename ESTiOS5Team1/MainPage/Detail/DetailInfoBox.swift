//
//  DetailInfoBox.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI
import Kingfisher

struct DetailInfoBox: View {
    let item: GameDetailItem

    var body: some View {
        KFImage(item.coverURL)
            .cacheOriginalImage()
            .loadDiskFileSynchronously()
            .placeholder {
                ProgressView()
            }
            .resizable()
            .scaledToFill()
            .frame(height: 400)
            .clipped()
            .cornerRadius(Radius.card)

        VStack(alignment: .leading) {
            HStack {
                KFImage(item.coverURL)
                    .cacheOriginalImage()
                    .loadDiskFileSynchronously()
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(height: 130)
                    .clipped()
                    .cornerRadius(Radius.cr8)

                VStack(alignment: .leading, spacing: 10) {
                    Text(item.title)
                        .font(.title)

                    Text("개발사")
                        .font(.caption)
                        .foregroundStyle(.gray.opacity(0.8))
                    Text(item.releaseYear)
                        .font(.caption)
                    Text(item.genre.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.pink.opacity(0.75))
                        .bold()
                        .padding(.horizontal, 5)
                        .background(.purple.opacity(0.2), in: Capsule())

                    ForEach(item.platforms, id: \.rawValue) { platform in
                        Image(systemName: platform.iconName)
                            .foregroundStyle(.textPrimary.opacity(0.6))
                            .font(.caption)
                    }

                }
            }
            .foregroundStyle(.textPrimary)
            Divider()
                .frame(height: 1)
                .background(.textPrimary.opacity(0.2))
            HStack {

                StatView(value: item.ratingText, title: "User Score", color: .mint)
                    .frame(maxWidth: .infinity)
                Divider()
                    .frame(height: 40)
                    .background(.textPrimary.opacity(0.2))

                StatView(value: item.metaScore, title: "Metacritic", color: .mint)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(.textPrimary.opacity(0.06))
        )

    }
}
