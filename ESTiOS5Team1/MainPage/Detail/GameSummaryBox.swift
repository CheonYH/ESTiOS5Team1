//
//  GameDetailBox.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/15/26.
//

import SwiftUI

// MARK: - Game Summary Box

/// 게임의 소개(About) 텍스트를 접기/펼치기 형태로 보여주는 뷰입니다.
///
/// 요약 문자열이 비어있으면 아무것도 표시하지 않으며,
/// 내용이 있을 때는 기본 4줄로 제한해 노출하고 “더 보기/접기”로 확장합니다.

struct GameSummaryBox: View {
    /// 상세 화면에 표시할 게임 데이터 모델
    let item: GameDetailItem
    
    /// 소개 텍스트의 펼침/접힘 상태
    @State private var isExpanded = false
    var body: some View {
        let description = item.summary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if description.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("About")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                
                Text(item.summary ?? "상세 설명 없음")
                    .font(.subheadline)
                    .foregroundStyle(.textPrimary.opacity(0.8))
                    .lineLimit(isExpanded ? nil : 4)
                
                Button {
                    isExpanded.toggle()
                } label: {
                    Text(isExpanded ? "접기" : "더 보기")
                        .font(.caption.bold())
                        .foregroundStyle(.purplePrimary)
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(.textPrimary.opacity(0.06))
            )
        }
    }
}
