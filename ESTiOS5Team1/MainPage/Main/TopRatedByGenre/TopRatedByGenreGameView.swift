//
//  TopRatedByGenreGameView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/30/26.
//

import SwiftUI
import Kingfisher

// MARK: - View


/// 맞춤 추천 섹션에서 사용되는 추천 게임 카드 뷰입니다.
///
/// 커버 이미지와 핵심 정보를 카드 형태로 표시합니다.
struct TopRatedByGenreGameView: View {
    
    let item: GameListItem
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 5) {
                if let coverURL = item.coverURL {
                    KFImage(coverURL)
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 113)))
                        .placeholder {
                            GameListCardPlaceholder()
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 200)
                        .clipped()
                        .cornerRadius(Radius.cr8)
                } else {
                    GameListCardPlaceholder()
                        .frame(width: 150, height: 200)
                        .cornerRadius(Radius.cr8)
                }
                
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.textPrimary)
                
                Text(item.genre.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.textPrimary.opacity(0.7))
                
            }
            .frame(width: 150, height: 250)
            
            BookMarkOverlay(item: item, needText: false)
        }
    }
}

//#Preview {
//    TopRatedByGenreGameView()
//}
