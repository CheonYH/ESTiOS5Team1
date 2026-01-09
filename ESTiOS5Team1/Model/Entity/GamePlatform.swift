//
//  GamePlatform.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/7/26.
//

import Foundation

/// IGDB에서 받아온 플랫폼 이름을 담는 간단한 모델입니다.
///
/// `GameEntity` 단계에서 사용되며,
/// 플랫폼 이름을 앱 내부 로직에서 다루기 위한 타입입니다.
struct GamePlatform: Hashable {

    /// 플랫폼 이름 (IGDB에서 제공)
    ///
    /// 예:
    /// - "PlayStation 5"
    /// - "Xbox Series X|S"
    /// - "PC (Microsoft Windows)"
    let name: String
}

