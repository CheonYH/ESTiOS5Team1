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
    @ObservedObject private var alanCoordinator: AlanCoordinator

    @State private var isPresentingRooms = false
    @FocusState private var isComposerFocused: Bool

    private let bottomAnchorId = "bottom_anchor"

    init(
        room: ChatRoom,
        store: ChatSwiftDataStore,
        roomsViewModel: ChatRoomsViewModel,
        alanCoordinator: AlanCoordinator
    ) {
        self.roomsViewModel = roomsViewModel
        self.alanCoordinator = alanCoordinator

        _roomViewModel = StateObject(
            wrappedValue: ChatRoomViewModel(
                room: room,
                store: store,
                alanCoordinator: alanCoordinator
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                messagesList
            }
            .preferredColorScheme(.dark)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black.opacity(0.8), location: 0.7),
                            .init(color: .black, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 44)
                    .allowsHitTesting(false)

                    composerBar
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.black)
                }
            }
            .navigationTitle(roomViewModel.room.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarCapsule }
            .sheet(isPresented: $isPresentingRooms) {
                ChatRoomsView(roomsViewModel: roomsViewModel) { selectedRoom in
                    isPresentingRooms = false
                    roomsViewModel.select(room: selectedRoom)

                    Task {
                        await roomViewModel.reload(room: selectedRoom)
                        focusComposerSoon()
                    }
                }
            }
            .task {
                await roomViewModel.loadInitialMessages()
                focusComposerSoon()
            }
            .onAppear { focusComposerSoon() }
        }
    }

    private var playNowTint: Color { .purple }

    private var toolbarCapsule: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 0) {
                Button {
                    Task {
                        let sourceRoomId = roomViewModel.room.identifier
                        let archivedRoom = await roomsViewModel.startNewConversation()

                        if let archivedRoom {
                            roomViewModel.redirectCompletions(from: sourceRoomId, to: archivedRoom.identifier)
                            alanCoordinator.redirectActiveRoom(from: sourceRoomId, to: archivedRoom.identifier) // ✅ 추가
                        }

                        await roomViewModel.reload(room: roomsViewModel.defaultRoom)
                        roomsViewModel.select(room: roomsViewModel.defaultRoom)
                        focusComposerSoon()
                    }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("새로운 채팅 시작")

                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 22)

                Button {
                    isPresentingRooms = true
                } label: {
                    Image(systemName: "text.bubble")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("채팅방 열기")
            }
            .tint(playNowTint)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
        }
    }

    private func focusComposerSoon() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            isComposerFocused = true
        }
    }

    private var isCurrentProcessingRoom: Bool {
        alanCoordinator.isBusy && alanCoordinator.activeRoomId == roomViewModel.room.identifier
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(roomViewModel.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.identifier)
                    }

                    // ✅ 현재 처리 중인 방만 도트 표시
                    if isCurrentProcessingRoom {
                        TypingBubbleView()
                            .transition(.opacity)
                    }

                    if let errorMessage = roomViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorId)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 10)
            }
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if roomViewModel.messages.isEmpty {
                    emptyNotice
                }
            }
            .task { scrollToBottom(proxy: proxy, animated: false) }
            .onChange(of: roomViewModel.messages) { _, _ in
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: alanCoordinator.isBusy) { _, _ in
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: alanCoordinator.activeRoomId) { _, _ in
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: isComposerFocused) { _, focused in
                guard focused else { return }
                scrollToBottom(proxy: proxy, animated: true)
            }
        }
    }

    private var emptyNotice: some View {
        VStack(spacing: 12) {
            Text("이 채팅은 AI가 생성한 정보를 제공합니다.")
                .font(.callout.weight(.semibold))

            Text("답변에는 부정확하거나 오래된 정보가 포함될 수 있습니다.\n중요한 판단은 반드시 공식 자료를 확인해 주세요.")
                .font(.footnote)

            Divider().opacity(0.4)

            Text("This chat provides AI-generated content.")
                .font(.callout.weight(.semibold))

            Text("Responses may be inaccurate or outdated.\nVerify important information with official sources.")
                .font(.footnote)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 24)
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

    private var placeholderText: String {
        alanCoordinator.isBusy ? "사용 중입니다" : "게임에 대해 질문하세요"
    }

    private var composerBar: some View {
        HStack(spacing: 10) {
            TextField(placeholderText, text: $roomViewModel.inputText, axis: .vertical)
                .lineLimit(1...4)
                .disabled(alanCoordinator.isBusy)
                .focused($isComposerFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                isComposerFocused = false
                Task { await roomViewModel.sendMessage() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(playNowTint)
                    .clipShape(Circle())
            }
            .disabled(
                alanCoordinator.isBusy ||
                roomViewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
            .accessibilityLabel("메시지 전송")
        }
    }
}
