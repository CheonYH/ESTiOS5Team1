//
//  IGDBConfig.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation

/// IGDB API 인증 정보를 관리하는 설정 타입입니다.
///
/// `Info.plist`에 저장된 민감한 인증 값(Client ID, Access Token)을
/// 앱 전반에서 안전하게 접근할 수 있도록 중앙에서 관리합니다.
///
/// - Important:
/// 이 값들은 **소스 코드에 직접 하드코딩하지 않고**
/// `Info.plist`를 통해 주입되어야 합니다.
/// 값이 누락된 경우 앱은 즉시 크래시(fatalError)됩니다.
///
/// - Note:
/// 추후 토큰 갱신 로직이 추가될 경우,
/// `accessToken`은 Keychain 또는 Secure Storage로 이전될 수 있습니다.
enum IGDBConfig {

    /// IGDB Client ID
    ///
    /// IGDB API 요청 시 `Client-ID` 헤더에 사용됩니다.
    /// `Info.plist`에 `IGDBClientID` 키로 등록되어 있어야 합니다.
    ///
    /// - Warning:
    /// 값이 존재하지 않을 경우 앱은 실행 중 즉시 종료됩니다.
    static let clientID: String = {
        guard let value = Bundle.main.object( forInfoDictionaryKey: "IGDBClientID" ) as? String else {
            fatalError("IGDBClientID not set")
        }

        print("[IGDBConfig] client length:", value.count)
        return value
    }()

    /// IGDB Access Token
    ///
    /// IGDB API 요청 시 `Authorization: Bearer {token}` 헤더에 사용됩니다.
    /// `Info.plist`에 `IGDBAccessToken` 키로 등록되어 있어야 합니다.
    ///
    /// - Important:
    /// 이 토큰은 **유효 기간이 존재**하므로,
    /// 장기적으로는 서버 또는 Firebase Functions 등을 통해
    /// 동적 발급/갱신 구조로 전환하는 것이 바람직합니다.
    static let accessToken: String = {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: "IGDBAccessToken"
        ) as? String else {
            fatalError("IGDBAccessToken not set")
        }

        print("[IGDBConfig] token length:", value.count)

        return value
    }()
}
