//
//  StatView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI

// MARK: - StatView

/// 스탯/요약 정보를 간단한 세로 레이아웃으로 보여주는 뷰입니다.
///
/// 숫자(또는 텍스트) 값과 제목을 한 묶음으로 표시할 때 사용합니다.
/// 예) 유저 점수, 리뷰 개수, 즐겨찾기 개수 등
struct StatView: View {
    
    /// 상단에 표시할 값(주로 숫자 문자열)
    let value: String
    
    /// 하단에 표시할 라벨(값의 의미)
    let title: String
    
    /// 값 텍스트에 적용할 강조 색상
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    StatView(value: "4", title: "User Score", color: .black)
}
