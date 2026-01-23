//
//  GameReviewEntity.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/22/26.
//

import Foundation

struct GameReviewEntity: Sendable {
    /// 리뷰 통계 정보를 담습니다.
    let stats: ReviewStatsResponse?
    /// 현재 사용자 리뷰를 담습니다. (없을 수 있음)
    let myReview: ReviewResponse?
    /// 다른 사용자 리뷰 목록을 담습니다.
    let others: [ReviewResponse]
}

extension GameReviewEntity {
    /// 전체 리뷰 목록과 내 리뷰를 분리해 엔티티를 생성합니다.
    init(reviews: [ReviewResponse], stats: ReviewStatsResponse?, myReview: ReviewResponse?) {
        self.stats = stats
        self.myReview = myReview

        if let myReviewId = myReview?.id {
            // 내 리뷰는 others에서 제외합니다.
            self.others = reviews.filter { $0.id != myReviewId }
        } else {
            self.others = reviews
        }
    }
}
