//
//  ProfileDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/xx/26.
//

import Foundation

struct ProfileRequest: Codable, Hashable {
    let nickname: String
    let avatarUrl: String
}

struct ProfileResponse: Codable, Hashable {
    let id: Int
    let userId: Int
    let nickname: String
    let avatarUrl: String
}
