//
//  GameFactsBotModel.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/9/26.
//

import Combine
import Foundation
import StreamChat
import StreamChatSwiftUI
import SwiftUI
import UIKit

// MARK: - Theme

struct RGBAColor: Codable, Hashable {
    var redComponent: Double
    var greenComponent: Double
    var blueComponent: Double
    var alphaComponent: Double

    var swiftUIColor: Color {
        Color(
            .sRGB,
            red: redComponent,
            green: greenComponent,
            blue: blueComponent,
            opacity: alphaComponent
        )
    }

    var uiColor: UIColor {
        UIColor(
            red: redComponent,
            green: greenComponent,
            blue: blueComponent,
            alpha: alphaComponent
        )
    }

    static let white = RGBAColor(
        redComponent: 1,
        greenComponent: 1,
        blueComponent: 1,
        alphaComponent: 1
    )

    static let black = RGBAColor(
        redComponent: 0,
        greenComponent: 0,
        blueComponent: 0,
        alphaComponent: 1
    )
}

struct ChatbotTheme: Codable, Hashable {
    var background: RGBAColor
    var currentUserBubble: RGBAColor
    var otherUserBubble: RGBAColor
    var currentUserText: RGBAColor
    var otherUserText: RGBAColor
    var tint: RGBAColor

    static let `default` = ChatbotTheme(
        background: .init(redComponent: 1, greenComponent: 1, blueComponent: 1, alphaComponent: 1),
        currentUserBubble: .init(redComponent: 0.16, greenComponent: 0.48, blueComponent: 0.98, alphaComponent: 0.4),
        otherUserBubble: .init(redComponent: 0.18, greenComponent: 0.18, blueComponent: 0.20, alphaComponent: 1),
        currentUserText: .black,
        otherUserText: .black,
        tint: .init(redComponent: 0.16, greenComponent: 0.48, blueComponent: 0.98, alphaComponent: 1)
    )

    func makeStreamColors() -> ColorPalette {
        var colors = ColorPalette()
        colors.background = background.uiColor
        colors.tintColor = tint.swiftUIColor

        colors.messageCurrentUserBackground = [currentUserBubble.uiColor]
        colors.messageOtherUserBackground = [otherUserBubble.uiColor]
        colors.messageCurrentUserTextColor = currentUserText.uiColor
        colors.messageOtherUserTextColor = otherUserText.uiColor

        return colors
    }
}

// MARK: - Settings

struct StreamChatSettings: Codable, Hashable {
    var apiKey: String = ""
    var userId: String = ""
    var userName: String = "Player"
    var userToken: String = ""
    var channelCID: String = "messaging:game-facts-bot"
}

struct AlanSettings: Codable, Hashable {
    var isEnabled: Bool = false
    var projectId: String = ""
    var apiKey: String = ""
    var endpoint: String = ""
}

struct PromptSettings: Codable, Hashable {
    var systemPrompt: String = PromptExamples.gameFactsSystemPrompt
    var injectionNotes: String = PromptExamples.injectionNotes
}

struct AppSettings: Codable, Hashable {
    var theme: ChatbotTheme = .default
    var stream: StreamChatSettings = .init()
    var alan: AlanSettings = .init()
    var prompts: PromptSettings = .init()

    private static let storageKey = "GameFactsBot.AppSettings"

    static func load() -> AppSettings {
        guard
            let dataValue = UserDefaults.standard.data(forKey: storageKey),
            let decodedSettings = try? JSONDecoder().decode(AppSettings.self, from: dataValue)
        else { return .init() }
        return decodedSettings
    }

    func save() {
        guard let encodedData = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(encodedData, forKey: Self.storageKey)
    }
}

enum PromptExamples {
    static let gameFactsSystemPrompt = """
    You are GameFactsBot.
    Scope: video games only.

    HARD RULES:
    - Do NOT invent facts.
    - Only answer if you can cite credible sources.
    - Every answer must include a "Sources" section with URLs.
    - If sources are missing, say: "I can’t confirm that from credible sources."

    Output format:
    1) Answer (concise)
    2) Sources (bullet list of URLs)
    """

    static let injectionNotes = """
    Add constraints like:
    - Prefer IGDB for game metadata + cover images.
    - Prefer official wikis / patch notes for builds.
    - Prefer reputable guides (publisher sites, well-known communities).
    """
}

// MARK: - AppState

@MainActor
final class AppState: Combine.ObservableObject {
    enum ConnectionState: Equatable {
        case notConfigured
        case connecting
        case connected
        case failed(String)
    }

    @Published var settings: AppSettings = .load()
    @Published private(set) var connectionState: ConnectionState = .notConfigured

    private var streamChat: StreamChat?
    private var chatClient: ChatClient?

    func saveSettings() {
        settings.save()
        Task { await configureStreamIfPossible() }
    }

    func configureStreamIfPossible() async {
        let streamSettings = settings.stream

        guard !streamSettings.apiKey.isEmpty,
              !streamSettings.userId.isEmpty,
              !streamSettings.userToken.isEmpty
        else {
            connectionState = .notConfigured
            return
        }

        connectionState = .connecting

        guard let tokenValue = try? Token(rawValue: streamSettings.userToken) else {
            connectionState = .failed("Invalid Stream user token.")
            return
        }

        var clientConfig = ChatClientConfig(apiKey: .init(streamSettings.apiKey))
        clientConfig.isLocalStorageEnabled = true

        let client = ChatClient(config: clientConfig)
        chatClient = client

        let palette = settings.theme.makeStreamColors()
        let appearance = Appearance(colors: palette)
        streamChat = StreamChat(chatClient: client, appearance: appearance)

        let userInfo = UserInfo(
            id: streamSettings.userId,
            name: streamSettings.userName,
            imageURL: nil
        )

        do {
            try await client.connectUser(userInfo: userInfo, token: tokenValue)
            connectionState = .connected
        } catch {
            connectionState = .failed(error.localizedDescription)
        }
    }

    func rebuildStreamAppearanceIfPossible() {
        guard let client = chatClient else { return }
        let palette = settings.theme.makeStreamColors()
        let appearance = Appearance(colors: palette)
        streamChat = StreamChat(chatClient: client, appearance: appearance)
    }
}
