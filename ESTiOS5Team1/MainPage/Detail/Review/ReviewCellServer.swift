//
//  ReviewCellServer.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//


import SwiftUI

struct ReviewCellServer: View {
    let review: ReviewResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // 별점 표시 (입력 아님 / 표시만)
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: StarRatingStyle.symbolName(index: index, rating: review.rating))
                            .font(.caption)
                            .foregroundStyle(StarRatingStyle.color(index: index, rating: review.rating))
                    }
                }

                Spacer()

                Text(review.createdAt.formatted())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(review.content)
                .font(.callout)
                .foregroundStyle(.textPrimary.opacity(0.9))

            Text("by \(review.userId)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }
}
