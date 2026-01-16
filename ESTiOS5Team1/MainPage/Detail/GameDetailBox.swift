//
//  GameDetailBox.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/15/26.
//

import SwiftUI

struct GameDetailBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.headline)
                .foregroundStyle(.textPrimary)
            
            Text("게임 설명")
                .font(.subheadline)
                .foregroundStyle(.textPrimary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(.textPrimary.opacity(0.06))
        )
        
    }
}

#Preview {
    GameDetailBox()
}
