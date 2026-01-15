//
//  DetailInfoBox.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/13/26.
//

import SwiftUI
import Kingfisher

struct DetailInfoBox: View {
    let item: GameDetailItem
    var body: some View {
        
        AsyncImage(url: item.coverURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Color.gray.opacity(0.3)
        }
        .frame(height: 500)
        .clipped()
        VStack(alignment: .leading) {
            HStack() {
                KFImage(item.coverURL)
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .clipped()
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.title)
                    
                    Text("개발사")
                        .foregroundStyle(.gray.opacity(0.8))
                    
                    Text(item.genre.joined(separator: " · "))
                        .font(.callout)
                        .foregroundStyle(.pink.opacity(0.75))
                        .bold()
                        .padding(.horizontal, 5)
                        .background(.purple.opacity(0.2), in: Capsule())
                }
            }
            .foregroundStyle(.white)
            Divider()
                .frame(height: 1)
                .background(Color.white.opacity(0.2))
            HStack {
                
                StatView(value: item.ratingText, title: "User Score", color: .mint)
                    .frame(maxWidth: .infinity)
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.2))
                
                StatView(value: "Me", title: "Metacritic", color: .mint)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
        )
        
    }
}
