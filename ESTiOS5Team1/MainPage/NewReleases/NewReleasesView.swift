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
                        NavigationLink(destination: DetailView(item: item)) {
                            NewReleasesGameCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
            }
        }
        .task {
            await viewModel.load()
        }

    }
}
