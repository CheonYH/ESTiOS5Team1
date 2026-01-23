//
//  DetailView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI

struct DetailView: View {

    let gameId: Int
    @State var rating: Double = 4
    @StateObject private var viewModel: GameDetailViewModel

    init(gameId: Int) {
        self.gameId = gameId
        self._viewModel = StateObject(wrappedValue: GameDetailViewModel(gameId: gameId))
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ScrollView {
                    if let item = viewModel.item {
                        DetailInfoBox(item: item)
                        GameSummaryBox(item: item)
                    } else if viewModel.isLoading {
                        ProgressView("Loading...")
                            .padding()
                    } else if let error = viewModel.error {
                        Text("오류 발생: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    }
                    
                    TitleBox(title: "Ratings & Reviews", showsSeeAll: true, onSeeAllTap: nil)
                    
                    Review { _, _ in }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 4) {
                    Text("상세 정보")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
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

#Preview {
    DetailView(gameId: 119133)
}
