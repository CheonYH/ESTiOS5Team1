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
                    if viewModel.isLoading {
                        ProgressView("로딩 중")
                    } else if let error = viewModel.error {
                        VStack {
                            Text("오류발생")
                                .font(.headline)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(viewModel.items) { item in
                            NavigationLink(destination: DetailView(item: item)) {
                                TrendingNowGameCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
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

