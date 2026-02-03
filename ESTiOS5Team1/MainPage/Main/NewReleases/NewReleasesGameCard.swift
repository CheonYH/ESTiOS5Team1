//
//  SwiftUIView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/9/26.
//

import SwiftUI
import Kingfisher

// MARK: - New Releases Game Card

/// “신규 출시” 리스트에서 사용하는 게임 카드 셀 뷰입니다.
///
/// 커버 이미지, 타이틀/장르, 평점, 플랫폼 아이콘을 표시하고,
/// 우측에 즐겨찾기 토글 버튼을 제공합니다.
///
/// - Note:
///     커버 이미지는 Kingfisher의 다운샘플링 프로세서를 사용해
///     작은 썸네일 크기에 맞게 디코딩하여 메모리 사용량을 줄입니다.

struct NewReleasesGameCard: View {
    /// 리스트에 표시할 게임 아이템
    let item: GameListItem
    
    /// 즐겨찾기 상태를 관리하는 매니저
    @EnvironmentObject var favoriteManager: FavoriteManager
    
    var body: some View {
        HStack {
            if let coverURL = item.coverURL {
                KFImage(coverURL)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 160, height: 93)))
                    .placeholder {
                        GameListCardPlaceholder()
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(Radius.card)
            } else {
                GameListCardPlaceholder()
                    .frame(width: 100, height: 100)
                    .cornerRadius(Radius.card)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.title2)
                
                Text(item.genre.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.textPrimary.opacity(0.7))
                
                HStack {
                    RatingText(item: item)
                    
                    ForEach(item.platformCategories, id: \.rawValue) { platform in
                        Image(systemName: platform.iconName)
                            .foregroundStyle(.textPrimary.opacity(0.6))
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    GameFavoriteButton(isFavorite: favoriteManager.isFavorite(itemId: item.id), onToggle: {
                        favoriteManager.toggleFavorite(item: item)
                    }, frameWH: 36)
                    
                }
            }
            .foregroundStyle(.textPrimary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(.textPrimary.opacity(0.12))
        )
    }
}
