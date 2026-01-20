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
<<<<<<< HEAD
            
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
=======

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
                    ForEach(viewModel.items.prefix(3)) { item in
                        NavigationLink(destination: DetailView(gameId: item.id)) {
                            NewReleasesGameCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
            }
>>>>>>> origin/refactor/auth-views
        }
        .task {
            await viewModel.load()
        }

    }
}
