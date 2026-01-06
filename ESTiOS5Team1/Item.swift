//
//  Item.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
