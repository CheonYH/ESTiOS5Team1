//
//  IGDBInvolvedCompanyDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/21/26.
//

import Foundation
struct IGDBInvolvedCompanyDTO: Codable, Hashable, Identifiable {
    let id: Int
    let developer: Bool?
    let publisher: Bool?
    let company: IGDBCompanyDTO?
}
