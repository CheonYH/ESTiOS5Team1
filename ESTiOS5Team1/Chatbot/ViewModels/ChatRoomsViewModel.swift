//
//  ChatRoomsViewModel.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import Combine
import Foundation

@MainActor
final class ChatRoomsViewModel: ObservableObject {
    @Published private(set) var rooms: [ChatRoom] = []
    @Published private(set) var defaultRoom: ChatRoom

    // 현재 선택된 방 (RootTabView에서 사용)
    @Published var selectedRoomId: UUID

    // 편집/다중삭제
    @Published var isEditing: Bool = false
    @Published var selectedRoomIds: Set<UUID> = []

    private let store: ChatLocalStore

    private let defaultRoomTitle = "New Chat"
    private let defaultRoomMaxMessages: Int = 40
    private let defaultRoomMaxIdleSeconds: TimeInterval = 60 * 30

    init(store: ChatLocalStore) {
        self.store = store

        let createdDefaultRoom = ChatRoom(
            title: defaultRoomTitle,
            isDefaultRoom: true,
            alanClientIdentifier: "ios-\(UUID().uuidString)"
        )

        self.defaultRoom = createdDefaultRoom
        self.selectedRoomId = createdDefaultRoom.identifier
    }

    func load() async {
        let storedRooms = await store.loadRooms()

        if let existingDefaultRoom = storedRooms.first(where: { $0.isDefaultRoom }) {
            defaultRoom = existingDefaultRoom
        } else {
            await store.saveRooms([defaultRoom])
        }

        await refreshRooms()

        // 기본방이 선택이 아니면(예: 첫 실행/데이터 꼬임) 기본방으로 강제
        if selectedRoom() == nil {
            selectedRoomId = defaultRoom.identifier
        }

        await autoArchiveDefaultRoomIfNeeded()
    }

    func refreshRooms() async {
        let storedRooms = await store.loadRooms()

        rooms = storedRooms.sorted { roomA, roomB in
            if roomA.isDefaultRoom != roomB.isDefaultRoom {
                return roomA.isDefaultRoom
            }
            return roomA.updatedAt > roomB.updatedAt
        }

        // 저장소에서 defaultRoom의 최신(updatedAt/title 등)을 다시 반영
        if let latestDefaultRoom = storedRooms.first(where: { $0.isDefaultRoom }) {
            defaultRoom = latestDefaultRoom
        }
    }

    // MARK: - Selection

    func select(room: ChatRoom) {
        selectedRoomId = room.identifier

        // 편집중이었다면 선택 동작 시 편집 해제(원하면 유지해도 됨)
        if isEditing {
            isEditing = false
            selectedRoomIds.removeAll()
        }
    }

    func selectedRoom() -> ChatRoom? {
        if selectedRoomId == defaultRoom.identifier {
            return defaultRoom
        }
        return rooms.first(where: { $0.identifier == selectedRoomId })
    }

    // MARK: - GPT Style: Start new chat (+)

    // - 현재 기본 대화(진행 중)를 아카이브로 저장 (요약 제목 1줄)
    // - 기본 대화는 초기화하여 새 대화를 시작
    func startNewConversation() async {
        let defaultMessages = await store.loadMessages(roomIdentifier: defaultRoom.identifier)

        if defaultMessages.isEmpty == false {
            let summaryTitle = makeArchiveTitle(from: defaultMessages) ?? "Archived Chat"

            let archivedRoom = ChatRoom(
                title: summaryTitle,
                isDefaultRoom: false,
                alanClientIdentifier: defaultRoom.alanClientIdentifier,
                updatedAt: Date()
            )

            var storedRooms = await store.loadRooms()
            storedRooms.append(archivedRoom)

            // 기본방 메타데이터 초기화(제목/시간)
            storedRooms = storedRooms.map { room in
                guard room.identifier == defaultRoom.identifier else { return room }
                var updated = room
                updated.title = defaultRoomTitle
                updated.updatedAt = Date()
                return updated
            }

            await store.saveRooms(storedRooms)
            await store.saveMessages(defaultMessages, roomIdentifier: archivedRoom.identifier)
        }

        // 기본 대화 메시지 초기화
        await store.saveMessages([], roomIdentifier: defaultRoom.identifier)
        await store.touchRoomUpdatedAt(roomIdentifier: defaultRoom.identifier)

        // 기본방 제목도 초기화 (안전하게 한번 더)
        var roomsAfter = await store.loadRooms()
        roomsAfter = roomsAfter.map { room in
            guard room.identifier == defaultRoom.identifier else { return room }
            var updated = room
            updated.title = defaultRoomTitle
            updated.updatedAt = Date()
            return updated
        }
        await store.saveRooms(roomsAfter)

        await refreshRooms()

        // + 누르면 항상 “새 대화(기본방)”로 돌아오게
        selectedRoomId = defaultRoom.identifier
    }

    // MARK: - Auto archive default room when idle / too long

    /// 기본 대화가 너무 오래되었거나(무활동 30분) 메시지가 너무 많으면 아카이브로 넘기고 초기화.
    func autoArchiveDefaultRoomIfNeeded() async {
        let now = Date()
        let idleSeconds = now.timeIntervalSince(defaultRoom.updatedAt)
        let defaultMessages = await store.loadMessages(roomIdentifier: defaultRoom.identifier)

        let shouldArchiveByIdle = idleSeconds > defaultRoomMaxIdleSeconds && defaultMessages.isEmpty == false
        let shouldArchiveByCount = defaultMessages.count > defaultRoomMaxMessages

        guard shouldArchiveByIdle || shouldArchiveByCount else { return }

        await startNewConversation()
    }

    // MARK: - Editing / Multi delete

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
        let targets = selectedRoomIds
        guard targets.isEmpty == false else { return }

        var storedRooms = await store.loadRooms()
        storedRooms.removeAll { room in
            // default room은 삭제 불가
            guard room.isDefaultRoom == false else { return false }
            return targets.contains(room.identifier)
        }
        await store.saveRooms(storedRooms)

        selectedRoomIds.removeAll()
        isEditing = false

        // 선택중이던 방이 삭제됐으면 default로
        if targets.contains(selectedRoomId) {
            selectedRoomId = defaultRoom.identifier
        }

        await refreshRooms()
    }

    // MARK: - Helpers

    private func makeArchiveTitle(from messages: [ChatMessage]) -> String? {
        // 첫 번째 유저 메시지 기준 1줄 요약 (간단)
        if let firstUser = messages.first(where: { $0.author == .guest }) {
            let trimmed = firstUser.text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")

            if trimmed.isEmpty { return nil }
            return String(trimmed.prefix(40))
        }
        return nil
    }
}
