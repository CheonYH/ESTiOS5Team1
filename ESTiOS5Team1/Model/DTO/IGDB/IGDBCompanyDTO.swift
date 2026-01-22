//
//  IGDBCompanyDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation

/// IGDB 회사(개발사/배급사) 정보를 담는 DTO입니다.
struct IGDBCompanyDTO: Codable, Hashable, Identifiable {
    /// 회사 고유 ID입니다.
    let id: Int
    /// 회사 이름입니다.
    let name: String
}
