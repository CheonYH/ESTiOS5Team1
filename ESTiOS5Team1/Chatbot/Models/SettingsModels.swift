//
//  SettingsModels.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

// MARK: - Overview

/// Alan API 호출에 필요한 설정 모델입니다.
///
/// 이 파일의 목적
/// - endpoint/clientKey를 한 곳에서 관리합니다.
/// - UserDefaults에 저장/복원(Codable) 가능하게 유지합니다.
///
/// 연동 위치
/// - ChatRoomViewModel이 sendMessage 직전에 AppSettings.load()로 읽습니다.
/// - AlanAPIClient.Configuration.baseUrl 생성에 endpoint가 사용됩니다.
/// - includeLocalContext 등은 프롬프트 구성(ChatbotPrompts) 분기에서 쓰입니다.

private enum AlanDefaults {
    /// Info.plist/저장값이 비어 있을 때의 안전한 기본값입니다.
    static let defaultEndpoint = "https://kdt-api-function.azurewebsites.net"
    static let defaultClientKey = "c358e44a-da12-4388-be42-781f2289ecba"
}

/// Alan 관련 설정 묶음입니다.
///
/// endpoint: 베이스 URL 문자열(실제 요청 직전 URL 파싱/검증은 호출부에서 수행)
/// clientKey: 서버가 대화 문맥을 구분하는 식별자 성격
///
/// context 관련 값은 "로컬 대화 일부를 프롬프트에 포함할지"를 제어합니다.
/// 길이 제한이 있는 이유는 URL query 기반 요청에서 과도한 payload를 막기 위함입니다.
struct AlanSettings: Codable, Hashable {
    var endpoint: String
    var clientKey: String

    var includeLocalContext: Bool = true
    var contextMessageCount: Int = 8
    var maxContextCharacters: Int = 2500

    /// 기본값 우선순위: Info.plist -> AlanDefaults
    init(
        endpoint: String = Bundle.main.stringValue(forInfoPlistKey: "ALAN_ENDPOINT") ?? AlanDefaults.defaultEndpoint,
        clientKey: String = Bundle.main.stringValue(forInfoPlistKey: "ALAN_CLIENT_KEY") ?? AlanDefaults.defaultClientKey
    ) {
        self.endpoint = endpoint
        self.clientKey = clientKey
        applyFallbacksIfNeeded()
    }

    /// 공백/빈 문자열을 기본값으로 보정합니다.
    mutating func applyFallbacksIfNeeded() {
        let endpointTrimmed = endpoint.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if endpointTrimmed.isEmpty {
            endpoint = AlanDefaults.defaultEndpoint
        }

        let keyTrimmed = clientKey.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if keyTrimmed.isEmpty {
            clientKey = AlanDefaults.defaultClientKey
        }
    }
}

/// 앱 설정 루트 모델입니다.
///
/// 저장 방식
/// - UserDefaults에 JSON(Data)로 저장합니다.
/// - 로드 실패 시 기본값으로 복구합니다.
///
/// 연동 위치
/// - ChatRoomViewModel이 매 전송 직전에 load()를 호출해 최신 값을 반영합니다.
struct AppSettings: Codable, Hashable {
    var alan: AlanSettings = .init()

    private static let storageKey = "GameFactsBot.AppSettings"

    static func load() -> AppSettings {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           var decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            decoded.alan.applyFallbacksIfNeeded()
            return decoded
        }

        return .init()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

private extension Bundle {
    /// Info.plist 값은 trim 후 빈 문자열이면 nil 처리합니다.
    /// 이렇게 하면 상위 로직에서 자연스럽게 기본값으로 폴백됩니다.
    func stringValue(forInfoPlistKey key: String) -> String? {
        guard let raw = infoDictionary?[key] as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
