//
//  MainView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/6/26.
//

import SwiftUI
import Kingfisher

struct MainView: View {
    @State var imageColor: Color = .white
    @State var textColor: Color = .white
    @State var item: GameListItem

    var body: some View {
        VStack {
            TopBarView()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    MainPoster(imageColor: .white, textColor: .white, item: item)

                    TrendingNowGameView(item: item)
                    
                    BrowseByGenreGridView()
                    
                    TitleBox(title: "New Releases")
                    
                    NewReleasesView(item: item)
                }
            }
        }
    }
}

#Preview {
    MainView(item: GameListItem(
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
