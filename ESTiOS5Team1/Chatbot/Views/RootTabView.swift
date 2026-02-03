//
//  RootTabView.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI

struct RootTabView: View {
    @StateObject private var alanCoordinator = AlanCoordinator()
    @StateObject private var roomsViewModel: ChatRoomsViewModel
    private let store: ChatSwiftDataStore

    init() {
        let localStore = ChatSwiftDataStore()
        store = localStore
        _roomsViewModel = StateObject(wrappedValue: ChatRoomsViewModel(store: localStore))
    }

    var body: some View {
        Group {
            if let room = roomsViewModel.selectedRoom() {
                ChatRoomView(
                    room: room,
                    store: store,
                    roomsViewModel: roomsViewModel,
                    alanCoordinator: alanCoordinator
                )
            } else {
                Text("No rooms available.")
                    .foregroundStyle(.secondary)
            }
        }
        .task { await roomsViewModel.load() }
    }
}

#Preview("Gamebot") {
    RootTabView()
}
