//
//  SwiftUIView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/8/26.
//

import SwiftUI

struct BrowseByGenreGridView: View {
    @EnvironmentObject var favoriteManager: FavoriteManager

    private let rows = [
        GridItem(.fixed(140), spacing: 16),
        GridItem(.fixed(140), spacing: 16)
    ]
    var body: some View {
        VStack(alignment: .leading) {
            Text("장르")
                .font(.title2.bold())
                .foregroundStyle(Color("TextPrimary"))

            ScrollView(.horizontal, showsIndicators: false) {

                LazyHGrid(rows: rows, spacing: 15) {
                    ForEach(GameGenreModel.allCases) { genre in
                        NavigationLink {
                            SearchView(favoriteManager: favoriteManager, gameGenre: genre)
                                .environmentObject(favoriteManager)
                        } label: {
                            GenreCard(genre: genre)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    BrowseByGenreGridView()
}
