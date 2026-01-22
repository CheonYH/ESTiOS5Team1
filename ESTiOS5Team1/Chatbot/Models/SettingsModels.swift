//
//  SettingsModels.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

struct AlanSettings: Codable, Hashable {
    var endpoint: String
    var clientKey: String
    var includeLocalContext: Bool = true
    var contextMessageCount: Int = 8
    var maxContextCharacters: Int = 2500

    init(
        endpoint: String = Bundle.main.stringValue(forInfoPlistKey: "ALAN_ENDPOINT") ?? "",
        clientKey: String = Bundle.main.stringValue(forInfoPlistKey: "ALAN_CLIENT_KEY") ?? ""
    ) {
        self.endpoint = endpoint
        self.clientKey = clientKey
    }
}

struct AppSettings: Codable, Hashable {
    var alan: AlanSettings = .init()

    private static let storageKey = "GameFactsBot.AppSettings"

    static func load() -> AppSettings {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return decoded
        }
        return .init()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

// MARK: - Info.plist helpers
private extension Bundle {
    func stringValue(forInfoPlistKey key: String) -> String? {
        guard let raw = infoDictionary?[key] as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
