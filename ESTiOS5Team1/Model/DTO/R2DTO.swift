//
//  R2DTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/xx/26.
//

import Foundation

struct R2PresignRequest: Codable, Hashable {
    let filename: String
    let expiresIn: Int
}

struct R2PresignResponse: Codable, Hashable {
    let uploadUrl: String
    let key: String
    let publicUrl: String?
    let expiresIn: Int
}
