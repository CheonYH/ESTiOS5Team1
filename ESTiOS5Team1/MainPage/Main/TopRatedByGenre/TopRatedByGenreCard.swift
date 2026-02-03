//
//  TopRatedByGenreCard.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/30/26.
//

import SwiftUI

// MARK: - View


/// 사용자의 선호 장르를 기반으로 한 '맞춤 추천' 섹션 뷰입니다.
///
/// 가로 스크롤 추천 카드 목록을 로딩 상태/에러 상태와 함께 표시합니다.
struct TopRatedByGenreCard: View {
    /// topRatedVM에 해당하는 데이터 로더(ViewModel)입니다.
    @StateObject private var topRatedVM = TopRatedByGenreViewModel(service: IGDBServiceManager())
    
    var body: some View {
        VStack {
            TitleBox(title: "맞춤 추천", onSeeAllTap: nil)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    LoadableList(
                        isLoading: topRatedVM.isLoading,
                        error: topRatedVM.error,
                        items: topRatedVM.items,
                        destination: { item in
                            DetailView(gameId: item.id)
                        },
                        row: { item in
                            TopRatedByGenreGameView(item: item)
                        }
                    )
                }
            }
        }
        .task {
            await topRatedVM.loadPreferredGenre()
        }
        .onReceive(NotificationCenter.default.publisher(for: .preferredGenresDidChange)) { _ in
            Task { await topRatedVM.refresh() }
        }
    }
}

//#Preview {
//    TopRatedByGenreCard()
//}
