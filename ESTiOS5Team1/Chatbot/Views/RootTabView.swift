//
//  RootTabView.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI

struct RootTabView: View {
    private let store: ChatLocalStore
    @StateObject private var roomsViewModel: ChatRoomsViewModel

    init() {
        let localStore = ChatLocalStore()
        store = localStore
        _roomsViewModel = StateObject(wrappedValue: ChatRoomsViewModel(store: localStore))
    }

    var body: some View {
        Group {
            if let room = roomsViewModel.selectedRoom() {
                ChatRoomView(
                    room: room,
                    store: store,
                    roomsViewModel: roomsViewModel
                )
            } else {
                Text("No rooms available.")
                    .foregroundStyle(.secondary)
            }
        }
        .task { await roomsViewModel.load() }
    }
}

#Preview("GameFactsBot Host") {
    RootTabView()
}
