//
//  StatView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI

struct StatView: View {
    let value: String
    let title: String
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
    StatView(value: "8.9", title: "User Score", color: .black)
}
