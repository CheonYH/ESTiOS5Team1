//
//  ChatRoomView.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI

struct ChatRoomView: View {
    @StateObject private var roomViewModel: ChatRoomViewModel

    @ObservedObject private var roomsViewModel: ChatRoomsViewModel
    @State private var isPresentingRooms = false

    init(
        room: ChatRoom,
        store: ChatLocalStore,
        roomsViewModel: ChatRoomsViewModel,
        settingsProvider: @escaping () -> AppSettings
    ) {
        _roomViewModel = StateObject(
            wrappedValue: ChatRoomViewModel(
                room: room,
                store: store,
                alanClient: AlanAPIClient(),
                settingsProvider: settingsProvider
            )
        )
        self.roomsViewModel = roomsViewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesList
                composerBar
            }
            .navigationTitle(roomViewModel.room.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingRooms = true
                    } label: {
                        Image(systemName: "text.bubble")
                    }
                }
            }
            .sheet(isPresented: $isPresentingRooms) {
                ChatRoomsView(roomsViewModel: roomsViewModel) { selectedRoom in
                    isPresentingRooms = false
                    Task { await roomViewModel.reload(room: selectedRoom) }
                }
            }
            .task { await roomViewModel.load() }
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(roomViewModel.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.identifier)
                    }

                    if let errorMessage = roomViewModel.errorMessage {
                        Text("⚠️ \(errorMessage)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .onChange(of: roomViewModel.messages) { _, newMessages in
                guard let lastMessage = newMessages.last else { return }
                withAnimation {
                    proxy.scrollTo(lastMessage.identifier, anchor: .bottom)
                }
            }
        }
    }

    private var composerBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about games…", text: $roomViewModel.composerText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button {
                Task { await roomViewModel.sendGuestMessage() }
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .disabled(roomViewModel.isSending)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

private struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.author == .bot {
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
            }
        }
    }

    private var bubble: some View {
        Text(message.text)
            .padding(12)
            .background(message.author == .bot ? Color.gray.opacity(0.15) : Color.blue.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
