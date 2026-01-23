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

    private let bottomAnchorId = "bottom_anchor"

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
                alanClientKeyOverride: "e8c9e9ca-92ba-408b-8272-0505933a649f"
            )
        )
        self.roomsViewModel = roomsViewModel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                messagesList
            }
            .preferredColorScheme(.dark)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composerBar
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.clear)
            }
            .navigationTitle(roomViewModel.room.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await roomsViewModel.startNewConversation()
                            await roomViewModel.reload(room: roomsViewModel.defaultRoom)
                            focusComposerSoon()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(playNowTint)
                    .accessibilityLabel("Start new chat")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingRooms = true
                    } label: {
                        Image(systemName: "text.bubble")
                    }
                    .tint(playNowTint)
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

    private var playNowTint: Color { .purple }

    private func focusComposerSoon() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            isComposerFocused = true
        }
    }

    private var messagesList: some View {
        ZStack {
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

                        Color.clear
                            .frame(height: 1)
                            .id(bottomAnchorId)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                }
                .scrollDismissesKeyboard(.interactively)
                .task { scrollToBottom(proxy: proxy, animated: false) }
                .onChange(of: roomViewModel.messages) { _, _ in
                    scrollToBottom(proxy: proxy, animated: true)
                }
                .onChange(of: roomViewModel.isSending) { _, _ in
                    scrollToBottom(proxy: proxy, animated: true)
                }
                .onChange(of: isComposerFocused) { _, focused in
                    guard focused else { return }
                    scrollToBottom(proxy: proxy, animated: true)
                }
            }

            // 메시지 없을 때 AI고지
            if roomViewModel.messages.isEmpty {
                EmptyChatNoticeView()
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(bottomAnchorId, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottomAnchorId, anchor: .bottom)
        }
    }

    private var composerBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about games…", text: $roomViewModel.composerText, axis: .vertical)
                .lineLimit(1...4)
                .disabled(roomViewModel.isSending)
                .focused($isComposerFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                }

            Button {
                Task { await roomViewModel.sendGuestMessage() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(playNowTint)
                    .clipShape(Circle())
            }
            .disabled(
                roomViewModel.isSending ||
                roomViewModel.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
            .accessibilityLabel("Send message")
        }
    }
}

private struct EmptyChatNoticeView: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("이 채팅은 AI가 생성한 정보를 제공합니다.")
                .font(.callout.weight(.semibold))

            Text("""
            답변에는 부정확하거나 오래된 정보가 포함될 수 있습니다.
            중요한 판단은 반드시 공식 자료를 확인해 주세요.
            """)
            .font(.footnote)

            Divider()
                .opacity(0.4)

            Text("This chat provides AI-generated content.")
                .font(.callout.weight(.semibold))

            Text("""
            Responses may be inaccurate or outdated.
            Verify important information with official sources.
            """)
            .font(.footnote)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal, 24)
    }
}
