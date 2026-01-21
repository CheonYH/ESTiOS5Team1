//
//  GameListSeeAll.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/20/26.
//

import SwiftUI

struct GameListSeeAll: View {
    let title: String
    let query: String

    @StateObject private var viewModel: GameListSingleQueryViewModel

    init (title: String, query: String) {
        self.title = title
        self.query = query
        _viewModel = StateObject(
            wrappedValue: GameListSingleQueryViewModel(
                service: IGDBServiceManager(),
                query: query
            )
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                LoadableList(
                    isLoading: viewModel.isLoading,
                    error: viewModel.error,
                    items: viewModel.items,
                    destination: { item in
                        DetailView(gameId: item.id)
                    },
                    row: { item in
                        GameListRow(item: item)
                    }
                )
            }
            .padding(.horizontal, Spacing.pv10)
            .padding(.top, 12)
        }
        .background(Color.BG.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }
}
