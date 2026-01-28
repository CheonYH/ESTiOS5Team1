//
//  ReviewTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import SwiftUI

/// 리뷰 API/뷰모델 동작을 수동으로 테스트하는 화면입니다.
struct ReviewTestView: View {

    @StateObject private var viewModel = ReviewViewModel(service: ReviewServiceManager())
    @EnvironmentObject var toastManager: ToastManager

    @State private var tempGameId: String = ""
    @State private var tempRating: String = ""
    @State private var tempContent: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // MARK: - Input Section
            GroupBox("Input") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Game ID", text: $tempGameId)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)

                    TextField("Rating (1~5)", text: $tempRating)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)

                    TextField("Content", text: $tempContent)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Set to VM") {
                            viewModel.gameId = Int(tempGameId)
                            viewModel.rating = Int(tempRating)
                            viewModel.content = tempContent
                        }

                        Button("Clear") {
                            tempGameId = ""
                            tempRating = ""
                            tempContent = ""
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Action Buttons
            GroupBox("Actions") {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Post Review") {
                        Task {
                            let event = await viewModel.postReview()
                            toastManager.show(event)
                        }
                    }

                    Button("Fetch Reviews") {
                        Task { await viewModel.loadReviews() }
                    }

                    Button("Fetch Stats") {
                        Task { await viewModel.loadStats() }
                    }

                    Button("Fetch My Reviews") {
                        Task { await viewModel.loadMine() }
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Output Section
            GroupBox("Output") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {

                        if let stats = viewModel.stats {
                            Text("⭐️ Stats: avg=\(stats.averageRating), count=\(stats.reviewCount)")
                                .font(.headline)
                        }

                        Text("Reviews:")
                            .font(.headline)

                        ForEach(viewModel.reviews) { review in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("#\(review.id) ⭐️\(review.rating)")
                                    .font(.subheadline)
                                Text(review.content)
                                Text("by \(review.userId) at \(review.createdAt)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }

                        if !viewModel.myReviews.isEmpty {
                            Text("My Reviews:")
                                .font(.headline)
                            ForEach(viewModel.myReviews) { review in
                                Text("My Review \(review.id): \(review.rating) - \(review.content)")
                            }
                        }
                    }
                    .padding(4)
                }
                .frame(maxHeight: 300)
            }

            // MARK: - Status & Error
            if viewModel.isLoading {
                Text("Loading...")
                    .foregroundColor(.blue)
            }

            if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Review Test")
    }
}

#Preview {
    let toast = ToastManager()
    ReviewTestView()
        .environmentObject(toast)
}
