//
//  IGDBReleaseDateDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation

struct IGDBReleaseDateDTO: Codable, Hashable {
    let id: Int
    let year: Int?
    let date: Int?
}
