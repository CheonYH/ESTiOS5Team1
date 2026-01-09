//
//  Platform.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//

import Foundation

/// 앱 내부에서 사용하는 플랫폼 분류 enum입니다.
///
/// IGDB에서 제공하는 다양한 플랫폼 이름을
/// 앱에서 공통으로 사용할 수 있는 플랫폼 타입으로 정리하기 위해 사용됩니다.
///
/// - Important:
/// 이 enum은 **UI 표시 및 분류 목적**으로 사용되며,
/// 네트워크 계층이나 API 응답 모델에는 사용되지 않습니다.
enum Platform: String {

    case playstation
    case xbox
    case nintendo
    case pc
    case mobile
    case web
    case unknown

    /// 플랫폼에 대응하는 SF Symbols 아이콘 이름
    ///
    /// UI에서 플랫폼 아이콘을 표시할 때 사용됩니다.
    var iconName: String {
        switch self {
            case .playstation:
                return "playstation.logo"
            case .xbox:
                return "xbox.logo"
            case .nintendo:
                return "gamecontroller"
            case .pc:
                return "desktopcomputer"
            case .mobile:
                return "iphone"
            case .web:
                return "globe"
            case .unknown:
                return "questionmark"
        }
    }
}

extension Platform {

    /// IGDB 플랫폼 이름을 `Platform` enum으로 매핑하기 위한 규칙 목록
    ///
    /// 각 플랫폼에 해당하는 키워드를 기준으로
    /// IGDB의 다양한 플랫폼 이름을 하나의 플랫폼 타입으로 분류합니다.
    ///
    /// - Note:
    /// 키워드 순서는 매핑 우선순위에 영향을 주므로,
    /// 더 구체적인 키워드를 위에 두는 것이 좋습니다.
    private static let mappings: [(keywords: [String], platform: Platform)] = [

        // PlayStation 계열
        (["playstation"], .playstation),

        // Xbox 계열
        (["xbox"], .xbox),

        // Nintendo 계열
        (["nintendo"], .nintendo),

        // 모바일 플랫폼
        (["ios", "iphone", "ipad", "android"], .mobile),

        // PC 플랫폼
        (["pc", "windows", "mac", "linux", "steam", "epic"], .pc),

        // 웹 / 브라우저 기반
        (["web", "browser"], .web)
    ]

    /// IGDB에서 제공하는 플랫폼 이름을 기반으로 `Platform`을 생성합니다.
    ///
    /// 매핑 규칙에 해당하지 않는 경우 `.unknown`으로 처리합니다.
    ///
    /// - Parameter igdbName: IGDB API에서 전달된 플랫폼 이름
    nonisolated init(igdbName: String) {
        let name = igdbName.lowercased()

        for mapping in Self.mappings
        where mapping.keywords.contains(where: name.contains) {
            self = mapping.platform
            return
        }

        self = .unknown
    }
}
