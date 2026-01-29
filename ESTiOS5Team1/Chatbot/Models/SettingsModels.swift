//
//  SettingsModels.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

// 지금 단계에서는 endpoint와 client_id가 반드시 있어야 서버 호출이 가능하다.
// 나중에 로컬 파일/보안 저장소로 옮길 예정이므로, 여기 하드코딩은 임시 방편이다.
// 저장된 값이 비어 있으면 이 기본값으로 강제로 채운다.
private enum AlanDefaults {
    static let defaultEndpoint = "https://kdt-api-function.azurewebsites.net"
    static let defaultClientKey = "3833f10d-f734-4ee3-8ec3-a94897a1d9b4"
}

struct AlanSettings: Codable, Hashable {
    var endpoint: String
    var clientKey: String

    var includeLocalContext: Bool = true
    var contextMessageCount: Int = 8
    var maxContextCharacters: Int = 2500

    init(
        endpoint: String = Bundle.main.stringValue(forInfoPlistKey: "ALAN_ENDPOINT") ?? AlanDefaults.defaultEndpoint,
        clientKey: String = Bundle.main.stringValue(forInfoPlistKey: "ALAN_CLIENT_KEY") ?? AlanDefaults.defaultClientKey
    ) {
        self.endpoint = endpoint
        self.clientKey = clientKey
        applyFallbacksIfNeeded()
    }

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

struct AppSettings: Codable, Hashable {
    var alan: AlanSettings = .init()

    private static let storageKey = "GameFactsBot.AppSettings"

    static func load() -> AppSettings {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           var decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            // 예전에 저장된 값이 빈 문자열로 남아있을 수 있어, 로드 시점에 한 번 보정한다.
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
    func stringValue(forInfoPlistKey key: String) -> String? {
        guard let raw = infoDictionary?[key] as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
