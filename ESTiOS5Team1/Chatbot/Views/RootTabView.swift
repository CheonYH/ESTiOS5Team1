//
//  RootTabView.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI

struct RootTabView: View {
    // 채팅 데이터 저장소는 앱 생명주기 동안 유지되어야 하므로 Root에서 한 번만 만든다.
    private let store: ChatSwiftDataStore

    // 채팅방 목록/선택 상태는 화면 전환과 무관하게 유지되어야 하므로 StateObject로 보관한다.
    @StateObject private var roomsViewModel: ChatRoomsViewModel

    init() {
        let localStore = ChatSwiftDataStore()
        store = localStore
        _roomsViewModel = StateObject(wrappedValue: ChatRoomsViewModel(store: localStore))
    }

    var body: some View {
        Group {
            // 현재 선택된 방이 있으면 그 방으로 채팅 화면을 보여준다.
            // 선택된 방이 없으면(데이터 꼬임/초기 로드 실패) 안내 문구를 보여준다.
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
        // 앱 진입 시 저장된 채팅방 로드 및 기본방 처리
        .task { await roomsViewModel.load() }
    }
}

#Preview("Gamebot") {
    RootTabView()
}
