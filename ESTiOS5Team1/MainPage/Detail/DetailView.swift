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
                DetailViewTopBar()
                
                ScrollView {
                    DetailInfoBox(item: item)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("descriptionssdwdqrqgrgegerggergergregergergergregegergergergegeg")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.06))
                    )
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
