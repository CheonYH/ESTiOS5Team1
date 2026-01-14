//
//  ChatLocalStore.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

actor ChatLocalStore {
    private let fileManager = FileManager.default

    private var baseFolderUrl: URL {
        let baseUrl = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return baseUrl.appendingPathComponent("GameFactsBot", isDirectory: true)
    }

    private var roomsFileUrl: URL {
        baseFolderUrl.appendingPathComponent("rooms.json")
    }

    private func messagesFileUrl(roomIdentifier: UUID) -> URL {
        baseFolderUrl.appendingPathComponent("messages-\(roomIdentifier.uuidString).json")
    }

    // MARK: - Rooms

    func loadRooms() -> [ChatRoom] {
        ensureFolderExists()

        guard let dataValue = try? Data(contentsOf: roomsFileUrl) else {
            return ensureDefaultRoomExists(in: [])
        }

        if let decodedRooms = try? JSONDecoder().decode([ChatRoom].self, from: dataValue) {
            return ensureDefaultRoomExists(in: decodedRooms)
        }

        if let legacyRooms = try? JSONDecoder().decode([LegacyChatRoom].self, from: dataValue) {
            let migratedRooms: [ChatRoom] = legacyRooms.map { legacy in
                ChatRoom(
                    identifier: legacy.identifier,
                    title: legacy.title,
                    isDefaultRoom: false,
                    alanClientIdentifier: legacy.alanClientIdentifier,
                    updatedAt: legacy.updatedAt
                )
            }

            let finalRooms = ensureDefaultRoomExists(in: migratedRooms)
            saveRooms(finalRooms)
            return finalRooms
        }

        let fallbackRooms = ensureDefaultRoomExists(in: [])
        saveRooms(fallbackRooms)
        return fallbackRooms
    }

    func saveRooms(_ rooms: [ChatRoom]) {
        ensureFolderExists()

        let normalizedRooms = ensureDefaultRoomExists(in: rooms)
        guard let encodedData = try? JSONEncoder().encode(normalizedRooms) else { return }
        try? encodedData.write(to: roomsFileUrl, options: [.atomic])
    }

    func deleteRoomMessages(roomIdentifier: UUID) {
        ensureFolderExists()
        let fileUrl = messagesFileUrl(roomIdentifier: roomIdentifier)
        try? fileManager.removeItem(at: fileUrl)
    }

    // MARK: - Messages

    func loadMessages(roomIdentifier: UUID) -> [ChatMessage] {
        ensureFolderExists()
        let fileUrl = messagesFileUrl(roomIdentifier: roomIdentifier)

        guard let dataValue = try? Data(contentsOf: fileUrl),
              let decodedMessages = try? JSONDecoder().decode([ChatMessage].self, from: dataValue)
        else { return [] }

        return decodedMessages
    }

    func saveMessages(_ messages: [ChatMessage], roomIdentifier: UUID) {
        ensureFolderExists()
        let fileUrl = messagesFileUrl(roomIdentifier: roomIdentifier)

        guard let encodedData = try? JSONEncoder().encode(messages) else { return }
        try? encodedData.write(to: fileUrl, options: [.atomic])
    }

    // MARK: - Helpers

    private func ensureFolderExists() {
        if fileManager.fileExists(atPath: baseFolderUrl.path) == false {
            try? fileManager.createDirectory(at: baseFolderUrl, withIntermediateDirectories: true)
        }
    }

    private func ensureDefaultRoomExists(in rooms: [ChatRoom]) -> [ChatRoom] {
        if rooms.contains(where: { $0.isDefaultRoom }) {
            return rooms
        }

        // 기본방이 없으면 앞에 삽입
        var newRooms = rooms
        newRooms.insert(.defaultRoom, at: 0)
        return newRooms
    }
}

// MARK: - Legacy Migration

private struct LegacyChatRoom: Codable {
    var identifier: UUID
    var title: String
    var alanClientIdentifier: String
    var updatedAt: Date
}
