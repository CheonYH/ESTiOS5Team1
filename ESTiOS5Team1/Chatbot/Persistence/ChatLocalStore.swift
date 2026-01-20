//
//  ChatLocalStore.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation

actor ChatLocalStore {
    private let baseFolderName = "ESTiOS5Team1_ChatStore"
    private let roomsFileName = "rooms.json"

    func loadRooms() -> [ChatRoom] {
        ensureFolderExists()
        let url = roomsFileUrl()

        guard let data = try? Data(contentsOf: url) else { return [] }
        guard let rooms = try? JSONDecoder().decode([ChatRoom].self, from: data) else { return [] }
        return rooms
    }

    func saveRooms(_ rooms: [ChatRoom]) {
        ensureFolderExists()
        let url = roomsFileUrl()
        guard let data = try? JSONEncoder().encode(rooms) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    func loadMessages(roomIdentifier: UUID) -> [ChatMessage] {
        ensureFolderExists()
        let fileUrl = messagesFileUrl(roomIdentifier: roomIdentifier)

        guard let data = try? Data(contentsOf: fileUrl) else { return [] }
        guard let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return [] }
        return messages
    }

    func saveMessages(_ messages: [ChatMessage], roomIdentifier: UUID) {
        ensureFolderExists()
        let fileUrl = messagesFileUrl(roomIdentifier: roomIdentifier)

        guard let encodedData = try? JSONEncoder().encode(messages) else { return }
        try? encodedData.write(to: fileUrl, options: [.atomic])
    }

    // MARK: - Activity

    func touchRoomUpdatedAt(roomIdentifier: UUID) {
        var rooms = loadRooms()
        guard let index = rooms.firstIndex(where: { $0.identifier == roomIdentifier }) else { return }

        rooms[index].updatedAt = Date()
        saveRooms(rooms)
    }

    // MARK: - Internal

    private func ensureFolderExists() {
        let url = baseFolderUrl()
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func baseFolderUrl() -> URL {
        let docUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docUrl.appendingPathComponent(baseFolderName, isDirectory: true)
    }

    private func roomsFileUrl() -> URL {
        baseFolderUrl().appendingPathComponent(roomsFileName)
    }

    private func messagesFileUrl(roomIdentifier: UUID) -> URL {
        baseFolderUrl().appendingPathComponent("messages_\(roomIdentifier.uuidString).json")
    }
}
