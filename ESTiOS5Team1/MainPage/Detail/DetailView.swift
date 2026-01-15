//
//  DetailView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI

struct DetailView: View {
    let item: GameListItem
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack() {
                DetailTopBar()
                
                ScrollView {
                    DetailInfoBox(item: item)
                    
                    GameDetailBox()
                    
                    TitleBox(title: "Ratings & Reviews", showsSeeAll: true, onSeeAllTap: nil)
                        .padding(.vertical, 15)
                    
                    StarRatingView(rating: 4.5)
                }
            }
        }
    }
}
#Preview {
    DetailView(item: GameListItem(
        entity: GameEntity(
            id: 1,
            title: "Elden Ring",
            coverURL: URL(string: "https://images.igdb.com/igdb/image/upload/t_cover_big/co4jni.jpg"),
            rating: 9.7,
            genre: ["Action RPG", "Fantasy"], platforms: [
                GamePlatform(name: "PlayStation 5"),
                GamePlatform(name: "PC")
            ]
        )
    )
    )
    .padding()
    .background(Color.black)
}
