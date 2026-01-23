//
//  GameDetailBox.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/15/26.
//

import SwiftUI

struct GameSummaryBox: View {
    let item: GameDetailItem
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
