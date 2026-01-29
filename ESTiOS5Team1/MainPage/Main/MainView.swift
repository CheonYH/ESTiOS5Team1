//
//  MainView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/6/26.
//

import SwiftUI
import Kingfisher

struct MainView: View {
    @ObservedObject var viewModel: GameListSingleQueryViewModel
    @ObservedObject var trendingVM: GameListSingleQueryViewModel
    @ObservedObject var newReleasesVM: GameListSingleQueryViewModel
    // [수정] FavoriteManager 연동을 위해 추가
    @EnvironmentObject var favoriteManager: FavoriteManager
    @EnvironmentObject var tabBarState: TabBarState
    @State private var showRoot = false
    let onSearchTap: () -> Void
    let onGenreTap: (GameGenreModel) -> Void
    var body: some View {
        VStack {
            CustomNavigationHeader(
                title: "게임 창고",
                showSearchButton: true,
                isSearchActive: false,
                onSearchTap: { onSearchTap() },
                showRoot: $showRoot
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    if let item = viewModel.items.first {
                        MainPoster(item: item)
                    }

                    TrendingNowGameView(viewModel: trendingVM)

                    BrowseByGenreGridView(onGenreTap: onGenreTap)

                    NewReleasesView(viewModel: newReleasesVM)
                }
            }
            .scrollIndicators(.hidden)
            .padding(Spacing.pv10)
            .task {
                if viewModel.items.isEmpty {
                    await viewModel.load()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationDestination(isPresented: $showRoot) {
            RootTabView()
                .onAppear { tabBarState.isHidden = true }
                .onDisappear { tabBarState.isHidden = false }
        }
        .onAppear { tabBarState.isHidden = false }
    }
}
