//
//  MainView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/6/26.
//

import SwiftUI

struct MainView: View {
    @State var imageColor: Color = .white
    
    @State var item: GameListItem
    
    
    @ViewBuilder
    var topbar: some View {
        HStack() {
            Button {
                
            } label: {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(imageColor)
            }
            
            Spacer()
            
            Image(systemName: "book")
                .foregroundStyle(.purple)
            
            Text("GameVault")
            
            Spacer()
            
            Button {
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(imageColor)
            }
            
        }
        .padding(.horizontal, 30)
        Divider()
            .frame(height: 1)
            .background(Color.white.opacity(0.2))
    }
    var body: some View {
        VStack {
            // topbar
            topbar
                .zIndex(1)
            ScrollView {
                ZStack {
                    AsyncImage(url: item.coverURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(height: 400)
                    .clipped()
                    
                    
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("FEATURED")
                                .foregroundStyle(.white)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(.purple, in: Capsule())
                            
                            Text(item.ratingText)// 임시
                                .bold()
                                .padding(.vertical, 5)
                                .padding(.horizontal, 15)
                                .background(.yellow, in: Capsule())
                        }
                        
                        Text(item.title)
                            .font(.largeTitle)
                        
                        Text("Rise, Tarnished, and be guided by grace to brandish the power of the Elden Ring.")
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                        
                        Text(item.genre.joined(separator: " · "))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button {
                            
                        } label: {
                            Label("Play Now", systemImage: "play.fill")
                                .foregroundStyle(.white)
                                .background(.purple, in: RoundedRectangle(cornerRadius: 5))
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                        }
                        
                        
                        
                    }
                    
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
            genre: ["Action RPG", "Fantasy"]
        )
    )
    )
    .padding()
    .background(Color.black)
}
