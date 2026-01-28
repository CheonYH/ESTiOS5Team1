//
//  ReviewViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation
import Combine

/// 리뷰 등록/조회와 통계를 관리하는 ViewModel입니다.
@MainActor
final class ReviewViewModel: ObservableObject {

    /// 현재 대상 게임 ID입니다.
    @Published var gameId: Int?
    /// 작성 중인 평점 값입니다.
    @Published var rating: Int?
    /// 작성 중인 리뷰 내용입니다.
    @Published var content: String?

    /// 게임 전체 리뷰 목록입니다.
    @Published var reviews: [ReviewResponse] = []
    /// 내 리뷰 목록입니다.
    @Published var myReviews: [ReviewResponse] = []
    /// 리뷰 통계 정보입니다.
    @Published var stats: ReviewStatsResponse?

    /// 로딩 상태입니다.
    @Published var isLoading = false
    /// 에러 메시지입니다.
    @Published var errorMessage: String?

    /// 리뷰 API 서비스입니다.
    private let service: ReviewService

    /// 의존성을 주입해 초기화합니다.
    init(service: ReviewService) {
        self.service = service
    }

    /// 게임 리뷰 목록을 불러옵니다.
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

    /// 리뷰 통계 정보를 불러옵니다.
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

    @discardableResult
    func postReview() async -> FeedbackEvent {
        guard let gameId, let rating, let content else {
            return FeedbackEvent(.review, .warning, "게임/평점/내용을 입력해주세요.")
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await service.create(gameId: gameId, rating: rating, content: content)
            await loadReviews()
            await loadStats()
            await loadMine()
            return FeedbackEvent(.review, .success, "리뷰가 등록되었습니다.")
        } catch {
            errorMessage = "\(error)"
            return FeedbackEvent(.review, .error, "리뷰 등록에 실패했습니다.")
        }
    }

    @discardableResult
    func updateReview(id: Int) async -> FeedbackEvent {
        guard let rating, let content else {
            return FeedbackEvent(.review, .warning, "평점과 내용을 입력해주세요.")
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await service.update(id: id, rating: rating, content: content)
            await loadReviews()
            await loadStats()
            await loadMine()
            return FeedbackEvent(.review, .success, "리뷰가 수정되었습니다.")
        } catch {
            errorMessage = "\(error)"
            return FeedbackEvent(.review, .error, "리뷰 수정에 실패했습니다.")
        }
    }

    @discardableResult
    func deleteReview(id: Int) async -> FeedbackEvent {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await service.delete(id: id)
            await loadReviews()
            await loadStats()
            await loadMine()
            return FeedbackEvent(.review, .success, "리뷰가 삭제되었습니다.")
        } catch {
            errorMessage = "\(error)"
            return FeedbackEvent(.review, .error, "리뷰 삭제에 실패했습니다.")
        }
    }
}
