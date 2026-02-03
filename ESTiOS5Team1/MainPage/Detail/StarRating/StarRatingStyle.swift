//
//  StarRatingStyle.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//

import SwiftUI

/// 별점 UI에 사용되는 아이콘/색상 규칙을 모아둔 유틸리티입니다.
///
/// - 규칙:
///   - `index <= rating`이면 채워진 별(`star.fill`)과 노란색을 사용합니다.
///   - 그 외에는 빈 별(`star`)과 흐린 회색을 사용합니다.
enum StarRatingStyle {
    /// 별 인덱스와 선택된 점수에 따라 표시할 SF Symbol 이름을 반환합니다.
    ///
    /// - Parameters:
    ///   - index: 별의 위치(1부터)
    ///   - rating: 현재 점수
    /// - Returns: "star.fill" 또는 "star"
    static func symbolName(index: Int, rating: Int) -> String {
        index <= rating ? "star.fill" : "star"
    }
    
    /// 별 인덱스와 선택된 점수에 따라 표시할 색상을 반환합니다.
    ///
    /// - Parameters:
    ///   - index: 별의 위치(1부터)
    ///   - rating: 현재 점수
    /// - Returns: 채움(노랑) 또는 비채움(회색)
    static func color(index: Int, rating: Int) -> Color {
        index <= rating ? .yellow : .gray.opacity(0.5)
    }
}
