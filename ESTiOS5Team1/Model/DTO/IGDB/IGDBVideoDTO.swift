//
//  IGDBVideoDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation

struct IGDBVideoDTO: Codable, Hashable, Identifiable {
    let id: Int
    let name: String?
    let videoId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case videoId = "video_id"
    }
}
