//
//  StarRatingPicker.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//

import SwiftUI

/// 사용자가 별점을 선택할 수 있는 별점 피커 뷰입니다.
///
/// - Parameters:
///   - maxStars: 표시할 별 개수(기본 5)
///   - rating: 현재 선택된 별점(바인딩)
///
/// - Note:
///   개별 별 아이콘을 탭하면 해당 점수로 `rating`이 업데이트됩니다.
struct StarRatingPicker: View {
    /// 표시할 별 개수입니다. 기본값은 5입니다.
    var maxStars: Int = 5
    /// 선택된 별점 값입니다.
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...maxStars, id: \.self) { index in
                Image(systemName: StarRatingStyle.symbolName(index: index, rating: rating))
                    .font(.title3)
                    .foregroundStyle(StarRatingStyle.color(index: index, rating: rating))
                    .onTapGesture { rating = index }
                    .contentShape(Rectangle())
            }

            Spacer()

            Text("\(rating)/\(maxStars)")
                .font(.subheadline)
                .foregroundStyle(.textPrimary.opacity(0.8))
        }
    }
}
