//
//  TopRatedByGenreCard.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/30/26.
//

import SwiftUI

struct TopRatedByGenreCard: View {
    @StateObject private var topRatedVM = TopRatedByGenreViewModel(service: IGDBServiceManager())

    var body: some View {
        VStack {
            TitleBox(title: "AI 맞춤 추천", onSeeAllTap: nil)
            
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
            // 앱 켜서 메인 들어왔을 때도 한 번 로드
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
