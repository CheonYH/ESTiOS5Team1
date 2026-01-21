//
//  ReviewDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation

struct ReviewResponse: Codable, Identifiable, Sendable {
    let id: Int
    let gameId: Int
    let userId: Int
    let rating: Int
    let content: String
    let createdAt: Date
    let updatedAt: Date
}

struct ReviewStatsResponse: Codable, Sendable {
    let gameId: Int
    let averageRating: Double
    let reviewCount: Int
}

struct CreateReviewRequest: Codable, Sendable {
    var gameId: Int
    var rating: Int
    var content: String
}

struct UpdateReviewRequest: Codable, Sendable {
    let rating: Int?
    let content: String?
}
