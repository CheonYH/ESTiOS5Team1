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
    ///
    /// - Endpoint:
    ///     `GET /reviews/game/{gameId}`
    ///
    /// - Parameters:
    ///     - sort: 리뷰 정렬 옵션
    ///
    /// - Returns:
    ///     없음 (내부 상태 `reviews` 갱신)
    func loadReviews(sort: ReviewSortOption? = .latest) async {
        guard let gameId else { return }

        isLoading = true
        errorMessage = nil

        do {
            // 최신/오래된 순 정렬 옵션을 지원
            reviews = try await service.fetchByGame(gameId: gameId, sort: sort)
        } catch {
            errorMessage = "\(error)"
        }

        isLoading = false
    }

    /// 리뷰 통계 정보를 불러옵니다.
    ///
    /// - Endpoint:
    ///     `GET /reviews/game/{gameId}/stats`
    ///
    /// - Returns:
    ///     없음 (내부 상태 `stats` 갱신)
    func loadStats() async {
        guard let gameId else { return }

        isLoading = true
        errorMessage = nil

        do {
            // 평균 평점/리뷰 개수 등 통계 정보 로딩
            stats = try await service.stats(gameId: gameId)
        } catch {
            errorMessage = "\(error)"
        }

        isLoading = false
    }

    /// 내 리뷰 목록을 불러옵니다.
    ///
    /// - Endpoint:
    ///     `GET /reviews/me`
    ///
    /// - Returns:
    ///     없음 (내부 상태 `myReviews` 갱신)
    func loadMine() async {
        isLoading = true; errorMessage = nil

        do {
            // 내 리뷰 조회 (인증 토큰 필요)
            myReviews = try await service.me()
        } catch {
            errorMessage = "\(error)"
        }

        isLoading = false
    }

    @discardableResult
    /// 리뷰를 등록합니다.
    ///
    /// - Endpoint:
    ///     `POST /reviews`
    ///     (성공 후 재조회: `GET /reviews/game/{gameId}`, `GET /reviews/game/{gameId}/stats`, `GET /reviews/me`)
    ///
    /// - Returns:
    ///     처리 결과 `FeedbackEvent`
    func postReview() async -> FeedbackEvent {
        guard let gameId, let rating, let content else {
            return FeedbackEvent(.review, .warning, "게임/평점/내용을 입력해주세요.")
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 1) 리뷰 등록
            _ = try await service.create(gameId: gameId, rating: rating, content: content)
            // 2) 목록/통계를 다시 불러와 화면 일관성 유지
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
    /// 내 리뷰를 수정합니다.
    ///
    /// - Endpoint:
    ///     `PATCH /reviews/{id}`
    ///     (성공 후 재조회: `GET /reviews/game/{gameId}`, `GET /reviews/game/{gameId}/stats`, `GET /reviews/me`)
    ///
    /// - Parameters:
    ///     - id: 수정할 리뷰 ID
    ///
    /// - Returns:
    ///     처리 결과 `FeedbackEvent`
    func updateReview(id: Int) async -> FeedbackEvent {
        guard let rating, let content else {
            return FeedbackEvent(.review, .warning, "평점과 내용을 입력해주세요.")
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 수정 성공 후 최신 상태 반영
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
    /// 내 리뷰를 삭제합니다.
    ///
    /// - Endpoint:
    ///     `DELETE /reviews/{id}`
    ///     (성공 후 재조회: `GET /reviews/game/{gameId}`, `GET /reviews/game/{gameId}/stats`, `GET /reviews/me`)
    ///
    /// - Parameters:
    ///     - id: 삭제할 리뷰 ID
    ///
    /// - Returns:
    ///     처리 결과 `FeedbackEvent`
    func deleteReview(id: Int) async -> FeedbackEvent {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 삭제 후 목록/통계를 갱신
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
