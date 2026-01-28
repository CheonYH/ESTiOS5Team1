//
//  StarRatingView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/15/26.
//

import SwiftUI

struct StarRatingView: View {
    var maxStars: Int = 5
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
