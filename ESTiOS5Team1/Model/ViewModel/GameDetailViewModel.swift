//
//  GameDetailViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation
import Combine

/// 게임 상세 데이터를 로드하고 화면 표시용 모델로 변환하는 ViewModel입니다.
@MainActor
final class GameDetailViewModel: ObservableObject {
    /// 화면에서 사용하는 상세 아이템
    @Published var item: GameDetailItem?
    /// 로딩 상태 표시
    @Published var isLoading = false
    /// 에러 상태
    @Published var error: Error?

    /// 조회 대상 게임 ID입니다.
    private let gameId: Int
    /// IGDB API 서비스입니다.
    private let gameService: IGDBService
    /// 리뷰 API 서비스입니다.
    private let reviewService: ReviewService
    /// 상세 엔티티 캐시입니다. (리뷰/평점 실시간 갱신용)
    private var cachedDetailEntity: GameDetailEntity?

    /// 게임 ID와 서비스 의존성을 주입받습니다.
    init(gameId: Int, service: IGDBService? = nil, reviewService: ReviewService? = nil) {
        self.gameId = gameId
        self.gameService = service ?? IGDBServiceManager()
        self.reviewService = reviewService ?? ReviewServiceManager()
    }

    /// 단일 게임 상세 정보를 불러옵니다.
    ///
    /// - Endpoint:
    ///     `POST /v4/games` (IGDB 상세)
    ///     `GET /reviews/game/{gameId}/stats`
    ///     `GET /reviews/game/{gameId}`
    ///     `GET /reviews/me`
    ///
    /// - Returns:
    ///     없음 (내부 상태 `item` 갱신)
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let dto = try await gameService.fetchDetail(id: gameId)

            let stats = try await reviewService.stats(gameId: gameId)
            let list =  try await reviewService.fetchByGame(gameId: gameId, sort: .latest)
            // 내 리뷰는 전용 엔드포인트에서 가져와 분리합니다.
            let myReviews = try? await reviewService.me()
            let myReview = myReviews?.first(where: { $0.gameId == gameId })

            let reviewEntity = GameReviewEntity(reviews: list, stats: stats, myReview: myReview)

            let detailEntity = GameDetailEntity(gameListDTO: dto, reviewDTO: stats)
            self.cachedDetailEntity = detailEntity
            self.item = GameDetailItem(detail: detailEntity, review: reviewEntity)
        } catch {
            self.error = error
        }
    }

    /// 리뷰 변경 후 평점/리뷰 정보를 다시 불러와 화면을 갱신합니다.
    ///
    /// - Endpoint:
    ///     `GET /reviews/game/{gameId}/stats`
    ///     `GET /reviews/game/{gameId}`
    ///     `GET /reviews/me`
    ///
    /// - Returns:
    ///     없음 (내부 상태 `item` 갱신)
    func refreshReviewData() async {
        guard let detailEntity = cachedDetailEntity else { return }

        do {
            let stats = try await reviewService.stats(gameId: gameId)
            let list = try await reviewService.fetchByGame(gameId: gameId, sort: .latest)
            let myReviews = try? await reviewService.me()
            let myReview = myReviews?.first(where: { $0.gameId == gameId })

            let reviewEntity = GameReviewEntity(reviews: list, stats: stats, myReview: myReview)
            self.item = GameDetailItem(detail: detailEntity, review: reviewEntity)
        } catch {
            self.error = error
        }
    }
}
