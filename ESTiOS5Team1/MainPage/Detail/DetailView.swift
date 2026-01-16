//
//  DetailView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI

struct DetailView: View {

    let gameId: Int

    @StateObject private var viewModel: GameDetailViewModel

    init(gameId: Int) {
        self.gameId = gameId
        self._viewModel = StateObject(wrappedValue: GameDetailViewModel(gameId: gameId))
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack {
                DetailTopBar()

                ScrollView {
                    if let item = viewModel.item {
                        DetailInfoBox(item: item)

                        VStack(alignment: .leading) {
                            Text("Additional Info")
                        }

                    } else if viewModel.isLoading {
                        ProgressView("Loading...")
                            .padding()
                    } else if let error = viewModel.error {
                        Text("오류 발생: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    }
                    
                    GameDetailBox()
                    
                    TitleBox(title: "Ratings & Reviews", showsSeeAll: true, onSeeAllTap: nil)
                    
                    StarRatingView(rating: 4.5)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

}


#Preview {
    DetailView(gameId: 119133)
}


