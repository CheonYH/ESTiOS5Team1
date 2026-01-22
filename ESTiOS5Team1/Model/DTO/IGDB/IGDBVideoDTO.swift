//
//  IGDBVideoDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation

/// IGDB에서 제공하는 비디오(트레일러) 정보를 담는 DTO입니다.
struct IGDBVideoDTO: Codable, Hashable, Identifiable {
    /// 비디오 고유 ID입니다.
    let id: Int
    /// 비디오 제목입니다. (없을 수 있음)
    let name: String?
    /// 유튜브 영상 ID입니다.
    let videoId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case videoId = "video_id"
    }
}
