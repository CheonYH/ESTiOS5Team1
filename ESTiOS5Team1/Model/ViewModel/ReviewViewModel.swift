//
//  ReviewViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation
import Combine

@MainActor
final class ReviewViewModel: ObservableObject {

    @Published var gameId: Int?
    @Published var rating: Int?
    @Published var content: String?

    @Published var reviews: [ReviewResponse] = []
    @Published var myReviews: [ReviewResponse] = []
    @Published var stats: ReviewStatsResponse?

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: ReviewService

    init(service: ReviewService) {
        self.service = service
    }

    func loadReviews(sort: ReviewSortOption? = .latest) async {
        guard let gameId else { return }

        isLoading = true
        errorMessage = nil

        do {
            reviews = try await service.fetchByGame(gameId: gameId, sort: sort)
        } catch {
            errorMessage = "\(error)"
        }

        isLoading = false
    }

    func loadStats() async {
        guard let gameId else { return }

        isLoading = true
        errorMessage = nil

        do {
            stats = try await service.stats(gameId: gameId)
        } catch {
            errorMessage = "\(error)"
        }

        isLoading = false
    }

    func loadMine() async {
        isLoading = true; errorMessage = nil

        do {
            myReviews = try await service.me()
        } catch {
            errorMessage = "\(error)"
        }

        isLoading = false
    }

    func postReview() async {
        guard let gameId, let rating, let content else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await service.create(gameId: gameId, rating: rating, content: content)
            await loadReviews()
            await loadStats()
        } catch {
            errorMessage = "\(error)"
        }

        isLoading = false
    }

    func updateReview(id: Int) async {
        guard let rating, let content else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await service.update(id: id, rating: rating, content: content)
            await loadReviews()
            await loadStats()
        } catch {
            errorMessage = "\(error)"
        }

        isLoading = false
    }

    func deleteReview(id: Int) async {
        isLoading = true; errorMessage = nil

        do {
            try await service.delete(id: id)
            await loadReviews()
            await loadStats()
        } catch {
            errorMessage = "\(error)"
        }

        isLoading = false
    }
}
