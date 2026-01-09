//
//  SwiftUIView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/9/26.
//

import SwiftUI
import Kingfisher

struct NewReleasesGameCard: View {
    let item: GameListItem
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 15)
                .frame(width: .infinity, height: 150)
                .foregroundStyle(.gray.opacity(0.15))
            
            HStack {
                KFImage(item.coverURL)
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(height: 130)
                    .clipped()
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(item.title)
                    
                    Text(item.genre.joined(separator: " · "))
                        .font(.caption)
                    
                    HStack {
                        RatingText(item: item)
                        
                        Text("플랫폼 아이콘")
                        
                        Spacer()
                        
                        Button {
                            // 추가 버튼
                        } label: {
                            Image(systemName: "plus")
                                .padding(10)
                                .background(.purple, in: RoundedRectangle(cornerRadius: 8))
                        }
                        
                    }
                }
                .foregroundStyle(.white)
            }
            .padding()
        }
    }
}
