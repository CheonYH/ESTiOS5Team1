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

    @FocusState private var isComposerFocused: Bool

    init(
        room: ChatRoom,
        store: ChatLocalStore,
        roomsViewModel: ChatRoomsViewModel
    ) {
        _roomViewModel = StateObject(
            wrappedValue: ChatRoomViewModel(
                room: room,
                store: store,
                alanEndpointOverride: "https://kdt-api-function.azurewebsites.net",
                alanClientKeyOverride: "87f5b1e2-3360-44b6-b942-5062b93a7114"
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
                    Task {
                        await roomViewModel.reload(room: selectedRoom)
                        focusComposerSoon()
                    }
                }
            }
            .task {
                await roomViewModel.load()
                focusComposerSoon()
            }
            .onAppear {
                focusComposerSoon()
            }
        }
    }

    private func focusComposerSoon() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            isComposerFocused = true
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

                    if roomViewModel.isSending {
                        TypingBubbleView()
                            .transition(.opacity)
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
            .onChange(of: roomViewModel.isSending) { _, _ in
                if let last = roomViewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.identifier, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var composerBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about games…", text: $roomViewModel.composerText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .disabled(roomViewModel.isSending)

            Button {
                Task { await roomViewModel.sendGuestMessage() }
            } label: {
                if roomViewModel.isSending {
                    ProgressView()
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
            .disabled(roomViewModel.isSending || roomViewModel.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

private struct TypingBubbleView: View {
    @State private var phase: Int = 0
    @State private var timer: Timer?

    var body: some View {
        HStack {
            bubble
            Spacer(minLength: 40)
        }
        .onAppear {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private var bubble: some View {
        HStack(spacing: 6) {
            Dot(isOn: phase == 0)
            Dot(isOn: phase == 1)
            Dot(isOn: phase == 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityLabel("Bot is typing")
    }

    private struct Dot: View {
        let isOn: Bool

        var body: some View {
            Circle()
                .frame(width: 7, height: 7)
                .opacity(isOn ? 1.0 : 0.25)
                .animation(.easeInOut(duration: 0.25), value: isOn)
        }
    }
}
