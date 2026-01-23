//
//  IGDBInvolvedCompanyDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation

/// 게임과 연관된 회사 정보를 담는 DTO입니다.
struct IGDBInvolvedCompanyDTO: Codable, Hashable, Identifiable {
    /// 연관 정보 고유 ID입니다.
    let id: Int
    /// 개발사 여부입니다.
    let developer: Bool?
    /// 배급사 여부입니다.
    let publisher: Bool?
    /// 회사 상세 정보입니다.
    let company: IGDBCompanyDTO?
}
