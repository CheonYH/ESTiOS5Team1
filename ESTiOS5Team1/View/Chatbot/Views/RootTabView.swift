//
//  RootTabView.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI

// 앱의 “채팅 기능 루트 엔트리” 역할을 하는 뷰입니다.
//
// 여기서 하는 일은 최소만 유지합니다.
// - 공용 상태(AlanCoordinator, ChatRoomsViewModel, ChatSwiftDataStore)를 생성하고 수명 주기를 잡습니다.
// - 선택된 방이 있으면 ChatRoomView를 보여주고, 없으면 fallback 텍스트를 보여줍니다.
//
// 연동 구조
// - ChatSwiftDataStore: SwiftData/AES/Keychain 포함한 저장소(앱 단일 인스턴스로 공유)
// - ChatRoomsViewModel: 방 목록/기본 방 정책 + 현재 선택 방 관리
// - AlanCoordinator: 전송 직렬화 + isBusy/activeRoomId(타이핑 표시 기준)
struct RootTabView: View {
    // 전송 직렬화/typing 상태는 화면 전반에서 공유되어야 하므로 루트에서 1회 생성합니다.
    @StateObject private var alanCoordinator = AlanCoordinator()

    // 방 목록/선택 상태도 루트에서 공유해야, 방 목록 화면과 채팅 화면이 같은 상태를 봅니다.
    @StateObject private var roomsViewModel: ChatRoomsViewModel

    // 저장소는 앱 내에서 동일 인스턴스를 계속 써야(같은 키/같은 DB) 방/메시지 로드가 안정적입니다.
    private let store: ChatSwiftDataStore

    init() {
        // store를 지역 변수로 만든 뒤 동일 인스턴스를 ViewModel에도 주입합니다.
        // - store가 둘로 갈리면(각각 다른 DB 컨텍스트) 저장/로드가 엇갈릴 수 있습니다.
        let localStore = ChatSwiftDataStore()
        store = localStore
        _roomsViewModel = StateObject(wrappedValue: ChatRoomsViewModel(store: localStore))
    }

    var body: some View {
        Group {
            // 선택된 방이 있으면 해당 방 화면을 표시합니다.
            // - 방 전환은 roomsViewModel.selectedRoomId 변경으로 이루어집니다.
            if let room = roomsViewModel.selectedRoom() {
                ChatRoomView(
                    room: room,
                    store: store,
                    roomsViewModel: roomsViewModel,
                    alanCoordinator: alanCoordinator
                )
            } else {
                // 초기 로드 실패/데이터 손상 등 예외 케이스 대비용 표시입니다.
                Text("No rooms available.")
                    .foregroundStyle(.secondary)
            }
        }
        // 앱 시작 시 저장된 방/기본 방을 로드합니다.
        // - load() 내부에서 defaultRoom 복원, rooms 갱신, 자동 아카이브 정책까지 처리합니다.
        .task { await roomsViewModel.load() }
    }
}

#Preview("Gamebot") {
    RootTabView()
}
