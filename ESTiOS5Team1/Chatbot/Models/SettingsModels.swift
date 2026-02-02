//
//  SettingsModels.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

private enum AlanDefaults {
    static let defaultEndpoint = "https://kdt-api-function.azurewebsites.net"
    static let defaultClientKey = "c358e44a-da12-4388-be42-781f2289ecba"
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
