//
//  GameReview.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//
import SwiftUI

struct GameReview: Identifiable, Hashable {
    let id: UUID = UUID()
    let rating: Int
    let text: String
    let createdAt: Date = Date()
}
