//
//  ChatModels.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

// 기존 코드 전반에서 guest/bot을 사용하고 있어서 구조를 유지한다.
// 이후 필요하면 guest를 user로 바꾸는 리팩터는 "전 파일 동시 변경"으로 진행해야 안전하다.
enum ChatAuthor: String, Codable, Hashable {
    case guest
    case bot
}

// 기존 코드에서 ChatMessage.identifier를 직접 참조하므로 그대로 유지한다.
// Identifiable은 id를 identifier로 매핑해 SwiftUI에서 쓰기 편하게 한다.
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

// 기존 코드에서 ChatRoom(identifier: ...) 생성 및 room.identifier 접근을 사용하므로 그대로 유지한다.
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

// 여기부터는 "분류 모델 출력 라벨"을 문자열 하드코딩 없이 다루기 위한 타입들이다.
// 모델 출력은 문자열이지만, 앱 내부에서는 enum으로 변환해 사용한다.
// 이렇게 하면 오타/누락으로 인한 분기 버그를 줄일 수 있다.

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
