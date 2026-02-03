//
//  StarRatingView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/15/26.
//

import SwiftUI

/// 읽기 전용(표시용) 별점 뷰입니다.
///
/// - Parameters:
///   - maxStars: 표시할 별 개수(기본 5)
///   - rating: 표시할 점수(정수)
///
/// - Accessibility:
///   별점 텍스트를 하나의 접근성 요소로 묶어 스크린리더가 자연스럽게 읽도록 처리합니다.
struct StarRatingView: View {
    /// 표시할 별 개수입니다.
    var maxStars: Int = 5
    /// 표시할 별점 값입니다.
    let rating: Int

    var body: some View {
        VStack(spacing: 5) {
            Text("\(rating)")
                .font(.largeTitle)
                .foregroundStyle(.textPrimary)
                .bold()

            HStack {
                ForEach(1...maxStars, id: \.self) { index in
                    Image(systemName: StarRatingStyle.symbolName(index: index, rating: rating))
                        .font(.footnote)
                        .foregroundStyle(StarRatingStyle.color(index: index, rating: rating))
                        .accessibilityLabel("\(index) star")
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rating \(rating) out of \(maxStars)")

        }
        .frame(maxWidth: .infinity, maxHeight: 150, alignment: .leading)
        .padding()
    }
}

// #Preview {
//    StarRatingView(rating: 4.5)
// }
