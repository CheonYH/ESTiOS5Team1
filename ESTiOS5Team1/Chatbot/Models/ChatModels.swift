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

extension ChatRoom {
    static let defaultRoomIdentifier = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()

    static let defaultRoom = ChatRoom(
        identifier: defaultRoomIdentifier,
        title: "GameFactsBot",
        isDefaultRoom: true,
        alanClientIdentifier: "ios-default-room",
        updatedAt: Date()
    )
}
