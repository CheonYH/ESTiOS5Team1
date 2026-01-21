//
//  IGDBWebsiteDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation

struct IGDBWebsiteDTO: Codable, Hashable, Identifiable {
    let id: Int
    let category: Int?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        category = try container.decodeIfPresent(Int.self, forKey: .category)
        url = try container.decodeIfPresent(String.self, forKey: .url)
    }
}
