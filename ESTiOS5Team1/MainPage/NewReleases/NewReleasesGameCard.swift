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

    var body: some View {
            HStack {
                KFImage(item.coverURL)
                    .cacheOriginalImage()
                    .loadDiskFileSynchronously()
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(Radius.card)

                VStack(alignment: .leading) {
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

                        Button {
                            // 추가 버튼
                        } label: {
                            Image(systemName: "plus")
                                .padding(10)
                                .background(Color("PurplePrimary"), in: RoundedRectangle(cornerRadius: Radius.cr8))
                        }

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
