//
//  SwiftUIView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/8/26.
//

import SwiftUI

struct BrowseByGenreGridView: View {

    private let rows = [
        GridItem(.fixed(140), spacing: 16),
        GridItem(.fixed(140), spacing: 16)
    ]
    var body: some View {
        VStack(alignment: .leading) {
            Text("BrowseByGenre")
                .font(.title2.bold())
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {

                LazyHGrid(rows: rows, spacing: 15) {
                    ForEach(GameGenreModel.allCases) { genre in
                        GenreCard(genre: genre)
                    }
                }
            }
        }
    }
}

#Preview {
    BrowseByGenreGridView()
}
