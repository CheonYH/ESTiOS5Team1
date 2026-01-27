//
//  StarRatingPicker.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//

import SwiftUI

struct StarRatingPicker: View {
    var maxStars: Int = 5
    @Binding var rating: Int
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...maxStars, id: \.self) { index in
                Image(systemName: StarRatingStyle.symbolName(index: index, rating: rating))
                    .font(.title3)
                    .foregroundStyle(StarRatingStyle.color(index: index, rating: rating))
                    .onTapGesture { rating = index }
                    .contentShape(Rectangle())
                    .accessibilityLabel("\(index)점")
            }
            
            Spacer()
            
            Text("\(rating)/\(maxStars)")
                .font(.subheadline)
                .foregroundStyle(.textPrimary.opacity(0.8))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating \(rating) out of \(maxStars)")
    }
}

//#Preview {
//    StarRatingPicker()
//}
