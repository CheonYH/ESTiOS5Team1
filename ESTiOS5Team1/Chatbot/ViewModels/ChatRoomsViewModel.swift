//
//  ChatRoomsViewModel.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Foundation
import Combine

@MainActor
final class ChatRoomsViewModel: ObservableObject {
    @Published private(set) var rooms: [ChatRoom] = []
    @Published private(set) var defaultRoom: ChatRoom

    @Published var selectedRoomId: UUID

    @Published var isEditing: Bool = false
    @Published var selectedRoomIds: Set<UUID> = []

    private let store: ChatSwiftDataStore

    private let defaultRoomTitle: String = "New Chat"
    private let defaultRoomMaxMessages: Int = 40
    private let defaultRoomMaxIdleSeconds: TimeInterval = 60 * 30

    init(store: ChatSwiftDataStore) {
        self.store = store

        let createdDefaultRoom = ChatRoom(
            identifier: UUID(),
            title: defaultRoomTitle,
            isDefaultRoom: true,
            alanClientIdentifier: "ios-\(UUID().uuidString)",
            updatedAt: Date()
        )

        self.defaultRoom = createdDefaultRoom
        self.selectedRoomId = createdDefaultRoom.identifier
    }

    func load() async {
        let storedRooms = await store.loadRooms()

        if let existingDefault = storedRooms.first(where: { $0.isDefaultRoom }) {
            defaultRoom = existingDefault
        } else {
            await store.saveRooms([defaultRoom])
        }

        await refreshRooms()

        if selectedRoom() == nil {
            selectedRoomId = defaultRoom.identifier
        }

        await autoArchiveDefaultRoomIfNeeded()
    }

    func refreshRooms() async {
        let storedRooms = await store.loadRooms()
        rooms = storedRooms.sorted { $0.updatedAt > $1.updatedAt }
    }

    func selectedRoom() -> ChatRoom? {
        if defaultRoom.identifier == selectedRoomId { return defaultRoom }
        return rooms.first(where: { $0.identifier == selectedRoomId })
    }

    func select(room: ChatRoom) {
        selectedRoomId = room.identifier
    }

    func startNewConversation() async -> ChatRoom? {
        let defaultMessages = await store.loadMessages(roomIdentifier: defaultRoom.identifier)

        var archivedRoom: ChatRoom?

        if defaultMessages.isEmpty == false {
            let room = makeArchivedRoom(from: defaultMessages)
            archivedRoom = room

            await store.saveMessages(defaultMessages, roomIdentifier: room.identifier)

            var storedRooms = await store.loadRooms()

            if storedRooms.contains(where: { $0.identifier == defaultRoom.identifier }) == false {
                storedRooms.append(defaultRoom)
            }

            storedRooms.append(room)
            await store.saveRooms(storedRooms)
        }

        defaultRoom.title = defaultRoomTitle
        defaultRoom.alanClientIdentifier = "ios-\(UUID().uuidString)"
        defaultRoom.updatedAt = Date()

        await store.saveMessages([], roomIdentifier: defaultRoom.identifier)
        await store.touchRoomUpdatedAt(roomIdentifier: defaultRoom.identifier)

        var roomsAfterReset = await store.loadRooms()
        if let idx = roomsAfterReset.firstIndex(where: { $0.identifier == defaultRoom.identifier }) {
            roomsAfterReset[idx] = defaultRoom
        } else {
            roomsAfterReset.append(defaultRoom)
        }
        await store.saveRooms(roomsAfterReset)

        selectedRoomId = defaultRoom.identifier
        isEditing = false
        selectedRoomIds.removeAll()

        await refreshRooms()
        return archivedRoom
    }

    private func autoArchiveDefaultRoomIfNeeded() async {
        let defaultMessages = await store.loadMessages(roomIdentifier: defaultRoom.identifier)
        guard defaultMessages.isEmpty == false else { return }

        guard defaultMessages.count >= defaultRoomMaxMessages else { return }

        let archivedRoom = makeArchivedRoom(from: defaultMessages)
        await store.saveMessages(defaultMessages, roomIdentifier: archivedRoom.identifier)

        var storedRooms = await store.loadRooms()
        storedRooms.append(archivedRoom)
        await store.saveRooms(storedRooms)

        await store.saveMessages([], roomIdentifier: defaultRoom.identifier)
        await store.touchRoomUpdatedAt(roomIdentifier: defaultRoom.identifier)

        await refreshRooms()
    }

    private func makeArchivedRoom(from messages: [ChatMessage]) -> ChatRoom {
        let firstGuest = messages.first(where: { $0.author == .guest })
        let candidate = (firstGuest?.text ?? messages.first?.text ?? "")
        let title = normalizeRoomTitle(candidate)

        return ChatRoom(
            identifier: UUID(),
            title: title,
            isDefaultRoom: false,
            alanClientIdentifier: "ios-\(UUID().uuidString)",
            updatedAt: Date()
        )
    }

    private func normalizeRoomTitle(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let compact = trimmed
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let base = compact.isEmpty ? "Archived Chat" : compact
        let maxChars = 24
        if base.count <= maxChars { return base }
        return String(base.prefix(maxChars))
    }

    func toggleEditing() {
        isEditing.toggle()
        if isEditing == false {
            selectedRoomIds.removeAll()
        }
    }

    func toggleSelected(room: ChatRoom) {
        if selectedRoomIds.contains(room.identifier) {
            selectedRoomIds.remove(room.identifier)
        } else {
            selectedRoomIds.insert(room.identifier)
        }
    }

    func deleteSelectedRooms() async {
        guard selectedRoomIds.isEmpty == false else { return }

        var storedRooms = await store.loadRooms()
        storedRooms.removeAll { room in
            selectedRoomIds.contains(room.identifier) && room.isDefaultRoom == false
        }
        await store.saveRooms(storedRooms)

        if selectedRoomIds.contains(selectedRoomId) {
            selectedRoomId = defaultRoom.identifier
        }

        selectedRoomIds.removeAll()
        isEditing = false

        await refreshRooms()
    }

    func maybeArchiveDefaultRoomByIdleTime() async {
        let defaultMessages = await store.loadMessages(roomIdentifier: defaultRoom.identifier)
        guard let last = defaultMessages.last else { return }

        let idle = Date().timeIntervalSince(last.createdAt)
        guard idle >= defaultRoomMaxIdleSeconds else { return }

        _ = await startNewConversation()
    }
}
