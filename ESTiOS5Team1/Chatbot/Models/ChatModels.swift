//
//  ChatModels.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

enum ChatAuthor: String, Codable, Hashable {
    case guest
    case bot
}

struct ChatMessage: Codable, Hashable, Identifiable {
    var identifier: UUID = UUID()
    var author: ChatAuthor
    var text: String
    var createdAt: Date = Date()

    var id: UUID { identifier }

    init(
        identifier: UUID = UUID(),
        author: ChatAuthor,
        text: String,
        createdAt: Date = Date()
    ) {
        self.identifier = identifier
        self.author = author
        self.text = text
        self.createdAt = createdAt
    }
}

struct ChatRoom: Codable, Hashable, Identifiable {
    var identifier: UUID
    var title: String
    var isDefaultRoom: Bool
    var alanClientIdentifier: String
    var updatedAt: Date

    var id: UUID { identifier }

    init(
        identifier: UUID = UUID(),
        title: String,
        isDefaultRoom: Bool = false,
        alanClientIdentifier: String = "ios-\(UUID().uuidString)",
        updatedAt: Date = Date()
    ) {
        self.identifier = identifier
        self.title = title
        self.isDefaultRoom = isDefaultRoom
        self.alanClientIdentifier = alanClientIdentifier
        self.updatedAt = updatedAt
    }
}

enum GameDomainLabel: String, CaseIterable, Sendable {
    case game
    case nonGame = "non_game"
    case unknown

    static func fromModelLabel(_ label: String) -> GameDomainLabel {
        GameDomainLabel(rawValue: label) ?? .unknown
    }

    var isGame: Bool { self == .game }
    var isNonGameOrUnknown: Bool { self != .game }
}

enum GameIntentLabel: String, CaseIterable, Sendable {
    case gameGuide = "game_guide"
    case gameInfo = "game_info"
    case gameRecommend = "game_recommend"
    case nonGame = "non_game"
    case unknown

    static func fromModelLabel(_ label: String) -> GameIntentLabel {
        GameIntentLabel(rawValue: label) ?? .unknown
    }

    var isInGameDomain: Bool {
        switch self {
        case .gameGuide, .gameInfo, .gameRecommend:
            return true
        case .nonGame, .unknown:
            return false
        }
    }
}
