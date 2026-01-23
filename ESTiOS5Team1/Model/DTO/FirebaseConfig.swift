//
//  FirebaseConfig.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/19/26.
//

import Foundation

/// 서버에서 내려주는 Firebase 초기 설정 값 DTO입니다.
struct FirebaseConfig: Decodable {
    /// Firebase Web API Key
    let apiKey: String
    /// iOS App ID (GoogleService-Info.plist의 APP_ID)
    let appId: String
    /// FCM Sender ID
    let gcmSenderId: String
    /// Firebase 프로젝트 ID
    let projectId: String
    /// Storage 버킷 주소 (Optional)
    let storageBucket: String?
    /// OAuth client ID (Google 로그인용)
    let clientId: String
}
