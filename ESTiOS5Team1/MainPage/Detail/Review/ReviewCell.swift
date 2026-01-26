//
//  ReviewCell.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//

import SwiftUI

struct ReviewCell: View {
    let review: GameReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NickName")
            HStack {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: StarRatingStyle.symbolName(index: index, rating: review.rating))
                        .font(.caption)
                        .foregroundStyle(StarRatingStyle.color(index: index, rating: review.rating))
                }
            }
            Text(review.text)
                .font(.callout)
                .foregroundStyle(.textPrimary.opacity(0.9))
            
            Text(review.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.textPrimary.opacity(0.9))
            
            
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white.opacity(0.06))
        )
        
    }
}

//#Preview {
//    ReviewCell()
//}
