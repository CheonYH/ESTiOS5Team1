//
//  GenreCardView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/8/26.
//
import SwiftUI

struct GenreCard: View {

    let genre: GameGenreModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(genre.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 140)
                .clipped()
                .cornerRadius(Radius.cr16)

            VStack(alignment: .leading, spacing: 4) {
                Text(genre.displayName)
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))
            }
            .padding(10)
        }
    }
}
