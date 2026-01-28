//
//  ReviewSection.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//

import SwiftUI

struct ReviewSection: View {
    let gameId: Int

    @StateObject private var viewModel = ReviewViewModel(service: ReviewServiceManager())

    private var latestThree: [ReviewResponse] {
        Array(viewModel.reviews.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading) {
            Review { rating, content in
                viewModel.gameId = gameId
                viewModel.rating = rating
                viewModel.content = content

                Task {
                    await viewModel.postReview()
                }
            }

            // 상태 표시
            if viewModel.isLoading {
                Text("Loading...")
                    .foregroundStyle(.secondary)
            }

            if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
            }

            // 리스트(최신 3개)
            ForEach(latestThree) { review in
                ReviewCellServer(review: review)
            }
        }
        // 처음 진입 시 서버에서 불러오기
        .task {
            viewModel.gameId = gameId
            await viewModel.loadReviews(sort: .latest)
            await viewModel.loadStats()
        }

    }
}

// #Preview {
//    ReviewSection()
// }
