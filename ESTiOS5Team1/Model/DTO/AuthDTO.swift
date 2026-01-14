//
//  AuthDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation

struct LoginRequest: Codable, Hashable {
    let email: String
    let password: String
}

struct LoginResponse: Codable, Hashable {
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access"
        case refreshToken = "refresh"
    }
}

struct RefreshRequest: Codable {
    let refreshToken: String
}

typealias TokenPair = LoginResponse
