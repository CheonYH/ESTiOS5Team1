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
            ForEach(viewModel.items.prefix(3)) { item in
                NewReleasesGameCard(item: item)
            }
        }
        .task {
            await viewModel.load()
        }

    }
}
