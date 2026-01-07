//
//  Game.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//

import SwiftUI

// MARK: - Game Model
struct Game: Identifiable {
    let id: String
    let title: String
    let genre: String
    let releaseYear: String
    let rating: Double
    let imageName: String
    let platforms: [Platform]
}
