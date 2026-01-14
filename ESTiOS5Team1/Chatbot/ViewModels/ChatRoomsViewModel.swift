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
    @Published var selectedRoomIdentifier: UUID?

    private let store: ChatLocalStore

    init(store: ChatLocalStore) {
        self.store = store
    }

    func load() async {
        let loadedRooms = await store.loadRooms()

        // 최신 업데이트 순 정렬 (기본방이 있어도 정상 동작)
        rooms = loadedRooms.sorted { $0.updatedAt > $1.updatedAt }

        // 선택된 방이 없거나, 선택된 방이 사라졌다면 기본방 → 첫 방 순으로 재선택
        let selectedIsValid = selectedRoomIdentifier.map { id in
            rooms.contains(where: { $0.identifier == id })
        } ?? false

        if selectedIsValid == false {
            selectedRoomIdentifier = rooms.first(where: { $0.isDefaultRoom })?.identifier
                ?? rooms.first?.identifier
        }
    }

    func addRoom(title: String) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.isEmpty == false else { return }

        var newRoom = ChatRoom(title: trimmedTitle)
        newRoom.updatedAt = Date()

        rooms.insert(newRoom, at: 0)
        selectedRoomIdentifier = newRoom.identifier

        await store.saveRooms(rooms)
    }

    // 기본방 삭제 차단
    func deleteRoom(roomIdentifier: UUID) async {
        guard let roomToDelete = rooms.first(where: { $0.identifier == roomIdentifier }) else { return }
        guard roomToDelete.isDefaultRoom == false else { return } // 기본방 삭제 불가

        rooms.removeAll { $0.identifier == roomIdentifier }

        await store.saveRooms(rooms)
        await store.deleteRoomMessages(roomIdentifier: roomIdentifier)

        if selectedRoomIdentifier == roomIdentifier {
            selectedRoomIdentifier = rooms.first(where: { $0.isDefaultRoom })?.identifier
                ?? rooms.first?.identifier
        }
    }

    func selectedRoom() -> ChatRoom? {
        guard let selectedRoomIdentifier else { return rooms.first }
        return rooms.first { $0.identifier == selectedRoomIdentifier } ?? rooms.first
    }
}
