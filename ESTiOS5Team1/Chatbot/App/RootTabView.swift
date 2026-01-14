//
//  RootTabView.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI

struct RootTabView: View {
    private enum TabSelection: Hashable {
        case chat
        case aiKeys
    }

    private let store: ChatLocalStore

    @StateObject private var roomsViewModel: ChatRoomsViewModel
    @StateObject private var botSession = StreamBotSession()

    @State private var settings: AppSettings = .load()
    @State private var selectedTab: TabSelection = .chat
    @State private var didRunStartupTasks = false

    init() {
        let localStore = ChatLocalStore()
        store = localStore
        _roomsViewModel = StateObject(wrappedValue: ChatRoomsViewModel(store: localStore))
    }

    var body: some View {
        // 탭바 보이기: 아래 줄 사용
//        tabbedRoot

        // 탭바 숨기기(하단 버튼 제거): 위 줄 주석 + 아래 줄 주석 해제
         chatOnlyRoot
    }

    private var tabbedRoot: some View {
        TabView(selection: $selectedTab) {
            chatContent
                .tabItem { Label("Chat", systemImage: "message") }
                .tag(TabSelection.chat)

            AIIntegrationScreen(settings: $settings, botSession: botSession)
                .tabItem { Label("AI/Keys", systemImage: "gearshape") }
                .tag(TabSelection.aiKeys)
        }
        .task { await runStartupTasksIfNeeded() }
    }

    private var chatOnlyRoot: some View {
        chatContent
            .task { await runStartupTasksIfNeeded() }
    }

    private var chatContent: some View {
        Group {
            if let room = roomsViewModel.selectedRoom() {
                ChatRoomView(
                    room: room,
                    store: store,
                    roomsViewModel: roomsViewModel,
                    settingsProvider: { settings }
                )
            } else {
                Text("No rooms available.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func runStartupTasksIfNeeded() async {
        guard !didRunStartupTasks else { return }
        didRunStartupTasks = true

        await roomsViewModel.load()
        await botSession.connectBotIfPossible(credentials: settings.botStream)
    }
}
