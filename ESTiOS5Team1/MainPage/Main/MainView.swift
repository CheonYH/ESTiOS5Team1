//
//  MainView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/6/26.
//

import SwiftUI
import Kingfisher

struct MainView: View {
    @StateObject private var viewModel = GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.newReleases)
    // [수정] FavoriteManager 연동을 위해 추가
    @EnvironmentObject var favoriteManager: FavoriteManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        if let item = viewModel.items.first {
                            MainPoster(item: item)
                        }

                        TrendingNowGameView()

                        BrowseByGenreGridView()

                        NewReleasesView()
                    }
                }
                .scrollIndicators(.hidden)
                .padding(Spacing.pv10)
                .task {
                    await viewModel.load()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {

                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }

//                ToolbarItem(placement: .principal) {
//                    HStack(spacing: 4) {
//                        Image(systemName: "gamecontroller")
//                            .foregroundStyle(.purple)
//                        Text("게임 목록")
//                            .font(.title2)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                    }
//                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 검색 액션 NavigationLink(destination: SearchView(favoriteManager: favoriteManager)) {
                        // Image(systemName: "magnifyingglass")
                    // }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 0.5)
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(FavoriteManager())
}
