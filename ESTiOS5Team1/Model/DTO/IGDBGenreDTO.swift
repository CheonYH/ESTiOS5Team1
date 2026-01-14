//
//  IGDBGenreDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/8/26.
//

import Foundation
import Combine

struct IGDBGenreDTO: Codable, Hashable, Identifiable {

    /// IGDB에서 부여한 장르의 고유 식별자
    let id: Int

    /// 장르 이름 (예: Action, RPG, Adventure)
    let name: String
}
