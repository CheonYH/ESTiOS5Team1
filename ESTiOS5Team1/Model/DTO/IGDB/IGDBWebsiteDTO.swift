//
//  IGDBWebsiteDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation

/// IGDB 웹사이트 정보를 담는 DTO입니다.
struct IGDBWebsiteDTO: Codable, Hashable, Identifiable {
    /// 웹사이트 고유 ID입니다.
    let id: Int
    /// 웹사이트 카테고리 코드입니다. (공식/스토어 등)
    let category: Int?
    /// 웹사이트 URL 문자열입니다.
    let url: String?

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case url
    }

    /// 일부 필드가 누락될 수 있어 안전하게 디코딩합니다.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        category = try container.decodeIfPresent(Int.self, forKey: .category)
        url = try container.decodeIfPresent(String.self, forKey: .url)
    }
}
