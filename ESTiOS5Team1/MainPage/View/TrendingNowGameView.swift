//
//  TrendingNowGameView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI

struct TrendingNowGameView: View {
    let item: GameListItem
    
    @StateObject private var viewModel =
    GameListViewModel(service: IGDBServiceManager(), query: IGDBQuery.trendingNow)
    
    var body: some View {
        VStack(alignment: .leading) {
            TitleBox(title: "Trending Now")
            
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
                            TrendingNowGameCard(item: item)
                                .background(
                                    NavigationLink(destination: GameDetailView(item: item), label: {
                                        EmptyView()
                                    }
                                                  )
                                    .opacity(0)
                                )
                            
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadGames()
        }
    }
}

struct TitleBox: View {
    
    var title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Spacer()
            
            Button {
                // See All 버튼 이동
                // trending now와 new Releases에서 사용하니 분류할 것
            } label: {
                Text("See All")
                    .font(.title3.bold())
            }
        }
    }
}
