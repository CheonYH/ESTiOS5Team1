//
//  StarRatingView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/15/26.
//

import SwiftUI

struct StarRatingView: View {
    var maxStars: Int = 5
    let rating: Double
    var body: some View {
        VStack(spacing: 5) {
            Text("8.9")
                .font(.largeTitle)
                .bold()
            HStack {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: symbolName(for: index))
                        .font(.footnote)
                        .foregroundStyle(color(for: index))
                        .accessibilityLabel("\(index) star")
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rating \(rating) out of \(maxStars)")

        }
        .frame(maxWidth: .infinity, maxHeight: 150, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(.black.opacity(0.06))
        )
    }

    private func symbolName(for index: Int) -> String {
        let value = rating - Double(index)
        if value >= 0 { return "star.fill" }
        if value >= -0.5 { return "star.leadinghalf.filled" }
        return "star"
    }

    private func color(for index: Int) -> Color {
        let value = rating - Double(index)
        if value >= -0.5 { return .yellow }
        return .gray.opacity(0.5)
    }
}

#Preview {
    StarRatingView(rating: 4.5)
}
