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
                DetailViewTopBar()

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

                    VStack(alignment: .leading, spacing: 10) {
                        Text("About")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("descriptionssdwdqrqgrgegerggergergregergergergregegergergergegeg")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.06))
                    )
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


