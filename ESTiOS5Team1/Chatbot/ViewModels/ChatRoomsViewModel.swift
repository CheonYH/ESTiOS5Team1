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

    func startNewConversation() async {
        // 사용자가 +를 눌렀을 때 기대하는 동작
        // 1) 기본방에 대화가 있으면 "새 채팅방"으로 저장해서 목록에 추가
        // 2) 기본방은 비우고 새 대화를 시작

        let defaultMessages = await store.loadMessages(roomIdentifier: defaultRoom.identifier)

        if defaultMessages.isEmpty == false {
            let archivedRoom = makeArchivedRoom(from: defaultMessages)

            await store.saveMessages(defaultMessages, roomIdentifier: archivedRoom.identifier)

            var storedRooms = await store.loadRooms()

            if storedRooms.contains(where: { $0.identifier == defaultRoom.identifier }) == false {
                storedRooms.append(defaultRoom)
            }

            storedRooms.append(archivedRoom)
            await store.saveRooms(storedRooms)
        }

        // 기본방을 완전히 초기화한다.
        // 서버 측 컨텍스트를 방별로 분리하는 구조가 아니라도,
        // 클라이언트 식별자를 새로 발급해두면 섞임을 줄이는 데 도움이 된다.
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
    }

    private func autoArchiveDefaultRoomIfNeeded() async {
        let defaultMessages = await store.loadMessages(roomIdentifier: defaultRoom.identifier)
        guard defaultMessages.isEmpty == false else { return }

        // 메시지가 너무 많아지면 자동으로 보관
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
        // 제목은 첫 사용자 메시지를 우선 사용한다.
        // guest/bot 모델을 그대로 유지한다.
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
        let trimmed = raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let compact = trimmed
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

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

        await startNewConversation()
    }
}
