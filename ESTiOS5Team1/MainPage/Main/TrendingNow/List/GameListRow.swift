//
//  GameListRow.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/20/26.
//
import SwiftUI

struct GameListRow: View {
    let item: GameListItem

    var body: some View {
        HStack(spacing: 12) {
            // 썸네일
            AsyncImage(url: item.coverURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.black.opacity(0.25)
            }
            .frame(width: 70, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .foregroundStyle(Color("TextPrimary"))
                    .font(.headline)
                    .lineLimit(2)

                Text(item.genre.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.textPrimary.opacity(0.7))

                // 별점
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }
}
