//
//  ReviewCellServer.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//

import SwiftUI

/// 서버에서 내려온 리뷰(`ReviewResponse`)를 카드 형태로 표시하는 셀 뷰입니다.
///
/// - 표시 요소:
///   - 별점(5개 별 아이콘)
///   - 작성일
///   - 리뷰 내용
///   - 작성자 닉네임
struct ReviewCellServer: View {
    /// 표시할 리뷰 데이터입니다.
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
                    .foregroundStyle(.textPrimary.opacity(0.5))
            }

            Text(review.content)
                .font(.callout)
                .foregroundStyle(.textPrimary.opacity(0.9))

            Text("by \(review.nickname)")
                .font(.caption2)
                .foregroundStyle(.textPrimary.opacity(0.5))
        }
        .padding()
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }
}
