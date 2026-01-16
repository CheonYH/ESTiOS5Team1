//
//  NewReleasesView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/9/26.
//

import SwiftUI

struct NewReleasesView: View {
    @StateObject private var viewModel =
    GameListSingleQueryViewModel(service: IGDBServiceManager(), query: IGDBQuery.newReleases)

    var body: some View {
        VStack {
            TitleBox(title: "New Releases", showsSeeAll: true, onSeeAllTap: { print("뉴 릴리즈 이동")})
            
            LoadableList(
                isLoading: viewModel.isLoading,
                error: viewModel.error,
                items: viewModel.items,
                limit: 4,
                destination: { item in
                    DetailView(gameId: item.id)
                },
                row: { item in
                    NewReleasesGameCard(item: item)
                }
            )
        }
        .task {
            await viewModel.load()
        }

    }
}
