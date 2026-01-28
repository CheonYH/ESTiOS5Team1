//
//  StarRatingStyle.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//

import SwiftUI

enum StarRatingStyle {
    static func symbolName(index: Int, rating: Int) -> String {
        index <= rating ? "star.fill" : "star"
    }

    static func color(index: Int, rating: Int) -> Color {
        index <= rating ? .yellow : .gray.opacity(0.5)
    }
}
