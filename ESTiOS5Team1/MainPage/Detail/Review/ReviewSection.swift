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
    private var reviewList: [ReviewResponse] {
        Array(viewModel.reviews)
    }
    @State private var showAll: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            TitleBox(title: "리뷰", showsSeeAll: true, onSeeAllTap: { showAll = true })
            
            // 리스트(최신 3개)
            ForEach(latestThree) { review in
                ReviewCellServer(review: review)
            }
            
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
        }
        // 처음 진입 시 서버에서 불러오기
        .task {
            viewModel.gameId = gameId
            await viewModel.loadReviews(sort: .latest)
            await viewModel.loadStats()
        }
        .navigationDestination(isPresented: $showAll) {
            ZStack {
                Color.BG.ignoresSafeArea()
                
                ScrollView {
                    ForEach(latestThree) { review in
                        ReviewCellServer(review: review)
                    }
                }
            }
        }
        
        
    }
}

//#Preview {
//    ReviewSection()
//}
