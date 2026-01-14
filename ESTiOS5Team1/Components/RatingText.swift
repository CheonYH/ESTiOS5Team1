//
//  RatingText.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//
import SwiftUI

struct RatingText: View {
    let item: GameListItem

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
            Text(item.ratingText)
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.black)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.yellow)
        .cornerRadius(8)
        .padding(8)
    }
}
