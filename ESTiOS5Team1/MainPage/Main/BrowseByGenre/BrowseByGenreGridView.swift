
//
//  SwiftUIView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/8/26.
//

import SwiftUI

struct BrowseByGenreGridView: View {
    @EnvironmentObject var favoriteManager: FavoriteManager
    let onGenreTap: (GameGenreModel) -> Void
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
<<<<<<< HEAD
                        Button {                   
=======
                        Button {                         // ✅ CHANGED
>>>>>>> 33702dd4c7b5278e3fa8adc8cb421cada42e504b
                            onGenreTap(genre)
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
    BrowseByGenreGridView(onGenreTap: { _ in})
        .environmentObject(FavoriteManager())
}
