//
//  TrendingNowGameView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI

struct TrendingNowGameView: View {

    @StateObject private var viewModel =
    GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.trendingNow)

    var body: some View {
        VStack(alignment: .leading) {
            TitleBox(title: "Trending Now", showsSeeAll: true, onSeeAllTap: { print("트렌딩 나우 이동")})

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    LoadableList(
                        isLoading: viewModel.isLoading,
                        error: viewModel.error,
                        items: viewModel.items,
                        destination: { item in
                            DetailView(gameId: item.id)
                        },
                        row: { item in
                            TrendingNowGameCard(item: item)
                        }
                    )
                }
            }
            .ignoresSafeArea(edges: .horizontal)

        }
        .task {
            await viewModel.load()
        }
    }
}

#Preview {
    TrendingNowGameView()
}
