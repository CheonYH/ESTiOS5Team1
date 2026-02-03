//
//  RatingText.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//
import SwiftUI

/// 게임 리스트 카드에서 별점(평점)을 배지 형태로 표시하는 뷰입니다.
///
/// - Parameters:
///   - item: 평점 텍스트를 제공하는 게임 아이템(`ratingText` 사용)
///
/// - Note:
///   배경 색상은 `YellowPrimary` 에셋 컬러를 사용합니다.
struct RatingText: View {
    /// 평점 표시 대상 게임 아이템입니다.
    let item: GameListItem

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))

            Text(item.ratingText)
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.black)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color("YellowPrimary"))
        .cornerRadius(Radius.cr8)
    }
}
