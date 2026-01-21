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

    @State private var showAll: Bool = false
    var body: some View {
        VStack {
            TitleBox(title: "신규 출시", showsSeeAll: true, onSeeAllTap: { showAll = true})

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
        .navigationDestination(isPresented: $showAll) {
            GameListSeeAll(title: "신규 출시", query: IGDBQuery.newReleases)
        }

    }
}
