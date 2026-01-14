//
//  SettingsModels.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

struct BotStreamCredentials: Codable, Hashable {
    var apiKey: String = ""
    var botUserIdentifier: String = "alan_bot"
    var botUserDisplayName: String = "Alan Bot"
    var botUserToken: String = ""
}

struct AlanSettings: Codable, Hashable {
    var isEnabled: Bool = true
    var apiKey: String = ""
    var endpoint: String = "https://kdt-api-function.azurewebsites.net"

    // 필요 시만 사용 (401/403 뜨면 채움)
    var authHeaderField: String = ""
    var authHeaderPrefix: String = ""
}

struct AppSettings: Codable, Hashable {
    var botStream: BotStreamCredentials = .init()
    var alan: AlanSettings = .init()

    private static let storageKey = "GameFactsBot.AppSettings"

    static func load() -> AppSettings {
        guard
            let storedData = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(AppSettings.self, from: storedData)
        else { return .init() }
        return decoded
    }

    func save() {
        guard let encodedData = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(encodedData, forKey: Self.storageKey)
    }
}
