//
//  TrendingGameCard.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//
import SwiftUI
import Kingfisher

struct TrendingNowGameCard: View {
    /// 화면에 표시할 게임 아이템
    let item: GameListItem

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 5) {
                KFImage(item.coverURL)
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 200)
                    .clipped()
                    .cornerRadius(Radius.cr8)

                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.textPrimary)

                Text(item.genre.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.textPrimary.opacity(0.7))
            }
            .frame(width: 150, height: 250)

            BookMarkOverlay(item: item)
        }
    }
}
