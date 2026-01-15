//
//  MainPoster.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI

struct MainPoster: View {
    @State var imageColor: Color = .white
    @State var textColor: Color = .white

    let item: GameListItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: item.coverURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(height: 400)
            .clipped()
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("FEATURED")
                        .foregroundStyle(textColor)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(.purple, in: Capsule())

                    Text(item.ratingText)// 임시
                        .foregroundStyle(textColor)
                        .bold()
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(.yellow, in: Capsule())
                }

                Text(item.title)
                    .font(.largeTitle)
                    .foregroundStyle(textColor)

                Text("Rise, Tarnished, and be guided by grace to brandish the power of the Elden Ring.")
                    .font(.headline)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)

                Text(item.genre.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                HStack {
                    Button {
                        // 플레이 나우 기능
                    } label: {
                        Label("Play Now", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: 250)
                            .frame(height: 50)
                            .background(.purple, in: RoundedRectangle(cornerRadius: 15))
                    }

                    Button {
                        // 좋아요 기능
                    } label: {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            .padding()
        }
    }
}
