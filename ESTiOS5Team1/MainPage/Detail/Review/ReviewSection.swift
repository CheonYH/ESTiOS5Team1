//
//  ReviewSection.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//

import SwiftUI
import UIKit

struct ReviewSection: View {
    let gameId: Int

    @StateObject private var viewModel = ReviewViewModel(service: ReviewServiceManager())
    @State private var isEditingMyReview = false
    @EnvironmentObject private var toastManager: ToastManager
    @State private var keyboardHeight: CGFloat = 0
    
    private var myReview: ReviewResponse? {
        viewModel.myReviews.first(where: { $0.gameId == gameId })
    }

    private var isEditingOrCreating: Bool {
        isEditingMyReview || myReview == nil
    }

    private var latestThree: [ReviewResponse] {
        let filtered = viewModel.reviews.filter { $0.id != myReview?.id }
        return Array(filtered.prefix(3))
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading) {
                if let myReview {
                    if !isEditingMyReview {
                        Text("내 리뷰")
                            .font(.headline)
                            .foregroundStyle(.textPrimary)

                        ReviewCellServer(review: myReview)
                    }

                    if isEditingMyReview {
                        Review(
                            initialRating: myReview.rating,
                            initialContent: myReview.content,
                            submitTitle: "수정"
                        ) { rating, content in
                            viewModel.gameId = gameId
                            viewModel.rating = rating
                            viewModel.content = content

                            Task {
                                let event = await viewModel.updateReview(id: myReview.id)
                                toastManager.show(event)
                                if event.status == .success {
                                    isEditingMyReview = false
                                    await viewModel.loadMine()
                                }
                            }
                        }
                        .id("reviewEditor")

                        HStack {
                            Button("취소") {
                                isEditingMyReview = false
                            }
                            .buttonStyle(.bordered)

                            Spacer()
                        }
                        .padding(.top, 4)
                    } else {
                        HStack {
                            Button("수정") {
                                isEditingMyReview = true
                            }
                            .buttonStyle(.bordered)

                            Button("삭제") {
                                Task {
                                    let event = await viewModel.deleteReview(id: myReview.id)
                                    toastManager.show(event)
                                    if event.status == .success {
                                        await viewModel.loadMine()
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.bottom, 8)
                    }
                } else {
                    Review { rating, content in
                        viewModel.gameId = gameId
                        viewModel.rating = rating
                        viewModel.content = content

                        Task {
                            let event = await viewModel.postReview()
                            toastManager.show(event)
                            if event.status == .success {
                                await viewModel.loadMine()
                            }
                        }
                    }
                    .id("reviewEditor")
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
            .padding(.bottom, isEditingOrCreating ? keyboardHeight : 0)
            .onChange(of: isEditingOrCreating) { _, isEditing in
                guard isEditing else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("reviewEditor", anchor: .bottom)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                guard
                    let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                else { return }
                keyboardHeight = frame.height + 16
                if isEditingOrCreating {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("reviewEditor", anchor: .bottom)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
        }
        // 처음 진입 시 서버에서 불러오기
        .task {
            viewModel.gameId = gameId
            await viewModel.loadReviews(sort: .latest)
            await viewModel.loadStats()
            await viewModel.loadMine()
        }

    }
}

// #Preview {
//    ReviewSection()
// }
