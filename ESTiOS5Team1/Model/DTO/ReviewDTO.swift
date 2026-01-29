//
//  ReviewDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation

/// 리뷰 조회 응답 모델입니다.
struct ReviewResponse: Codable, Identifiable, Sendable {
    /// 리뷰 고유 ID입니다.
    let id: Int
    /// 대상 게임 ID입니다.
    let gameId: Int
    /// 작성자 사용자 ID입니다.
    let userId: Int
    /// 평점입니다. (1~5)
    let rating: Int
    /// 리뷰 내용입니다.
    let content: String
    /// 생성 시각입니다.
    let createdAt: Date
    /// 수정 시각입니다.
    let updatedAt: Date

    let nickname: String
}

/// 리뷰 통계 응답 모델입니다.
struct ReviewStatsResponse: Codable, Sendable {
    /// 대상 게임 ID입니다.
    let gameId: Int
    /// 평균 평점입니다.
    let averageRating: Double
    /// 리뷰 개수입니다.
    let reviewCount: Int
}

/// 리뷰 생성 요청 모델입니다.
struct CreateReviewRequest: Codable, Sendable {
    /// 대상 게임 ID입니다.
    var gameId: Int
    /// 평점 값입니다.
    var rating: Int
    /// 리뷰 내용입니다.
    var content: String
}

/// 리뷰 수정 요청 모델입니다.
struct UpdateReviewRequest: Codable, Sendable {
    /// 변경할 평점입니다. (없을 수 있음)
    let rating: Int?
    /// 변경할 리뷰 내용입니다. (없을 수 있음)
    let content: String?
}
