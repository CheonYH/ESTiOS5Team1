//
//  ChatRoomView.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI

// 이 뷰는 “채팅방 단일 화면”입니다.
//
// 화면 책임
// - 메시지 리스트(말풍선/링크/에러/타이핑)를 렌더링합니다.
// - 입력창(TextField)과 전송 버튼을 제공하고, 전송 액션을 ViewModel로 위임합니다.
// - 방 전환(방 목록 시트)과 새 채팅 시작(기본 방 리셋)을 툴바에서 제공합니다.
//
// 연동 구조
// - ChatRoomViewModel(@StateObject)
//   - 현재 방(room), 메시지(messages), 입력(inputText), 에러(errorMessage)를 소유합니다.
//   - sendMessage 내부에서 MessageGate/의도분류/AlanAPIClient/저장을 수행합니다.
// - ChatRoomsViewModel(@ObservedObject)
//   - 방 목록/기본 방 정책을 소유하며 startNewConversation으로 아카이브/리셋을 수행합니다.
// - AlanCoordinator(@ObservedObject)
//   - 전송을 1개로 직렬화하고, isBusy/activeRoomId로 “현재 처리 중인 방”을 알려줍니다.
//   - 이 화면은 그 값을 보고 입력 비활성화 및 타이핑 표시를 제어합니다.
//
// 구현 선택 이유
// - roomViewModel을 StateObject로 두어, 뷰 갱신에도 ViewModel 인스턴스가 유지되게 합니다.
// - roomsViewModel/alanCoordinator는 상위(RootTabView 등)에서 공유되는 상태라 ObservedObject로 주입받습니다.
struct ChatRoomView: View {
    @StateObject private var roomViewModel: ChatRoomViewModel
    @ObservedObject private var roomsViewModel: ChatRoomsViewModel
    @ObservedObject private var alanCoordinator: AlanCoordinator

    // 방 목록 시트 표시 여부입니다.
    @State private var isPresentingRooms = false

    // 입력창 포커스 제어입니다.
    // - 방 전환/화면 진입 시 포커스를 자동으로 주어 “바로 입력” UX를 만듭니다.
    @FocusState private var isComposerFocused: Bool

    // ScrollViewReader에서 바닥으로 스크롤할 앵커 id입니다.
    private let bottomAnchorId = "bottom_anchor"

    init(
        room: ChatRoom,
        store: ChatSwiftDataStore,
        roomsViewModel: ChatRoomsViewModel,
        alanCoordinator: AlanCoordinator
    ) {
        self.roomsViewModel = roomsViewModel
        self.alanCoordinator = alanCoordinator

        // roomViewModel은 이 화면에서 생명주기를 소유하므로 StateObject로 구성합니다.
        // - 방 변경은 reload(room:)로 처리하고, ViewModel 인스턴스 자체는 유지합니다.
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

            // 입력창은 safeAreaInset로 하단에 고정합니다.
            // - 키보드 등장/사라짐에도 레이아웃이 자연스럽게 따라가고,
            //   메시지 리스트는 위 영역에서만 스크롤됩니다.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    // 하단 바 위에 그라데이션을 얹어, 스크롤 콘텐츠가 입력창 뒤로 겹칠 때 자연스러운 페이드가 나오게 합니다.
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

            // 방 목록은 시트로 띄워, 현재 채팅 화면 컨텍스트를 유지한 채 방을 고르게 합니다.
            .sheet(isPresented: $isPresentingRooms) {
                ChatRoomsView(roomsViewModel: roomsViewModel) { selectedRoom in
                    isPresentingRooms = false
                    roomsViewModel.select(room: selectedRoom)

                    // 방 선택 후에는 roomViewModel의 room/messages를 교체하고, 입력 포커스를 복구합니다.
                    Task {
                        await roomViewModel.reload(room: selectedRoom)
                        focusComposerSoon()
                    }
                }
            }

            // 화면 진입 시 현재 방 메시지를 한 번 로드합니다.
            .task {
                await roomViewModel.loadInitialMessages()
                focusComposerSoon()
            }
            .onAppear { focusComposerSoon() }
        }
    }

    private var playNowTint: Color { .purple }

    // 상단 툴바 캡슐 버튼입니다.
    // - 좌: 새 채팅 시작(기본 방 리셋)
    // - 우: 방 목록 열기
    //
    // 새 채팅 시작에서 중요한 연결
    // - roomsViewModel.startNewConversation()은 기본 방 메시지를 아카이브 방으로 이동시킬 수 있습니다.
    // - 그 순간 “진행 중이던 요청”이 있으면 응답이 원래 방에 붙지 않게 redirect가 필요합니다.
    //   roomViewModel.redirectCompletions: 응답 저장 위치를 아카이브 방으로 변경
    //   alanCoordinator.redirectActiveRoom: 타이핑 표시(activeRoomId)도 같은 방으로 맞춤
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

    // 화면 전환 직후 포커스가 바로 안 잡히는 케이스를 방지하기 위해 약간의 딜레이 후 포커스를 줍니다.
    // - 시트 닫힘/방 전환/키보드 전환 타이밍에서 포커스가 튕기는 문제를 줄입니다.
    private func focusComposerSoon() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            isComposerFocused = true
        }
    }

    // 현재 화면의 방이 “처리 중인 방”인지 판별합니다.
    // - alanCoordinator.activeRoomId가 이 방과 같을 때만 타이핑 버블을 보여줍니다.
    // - 방을 이동했는데도 타이핑 표시가 남는 문제를 막기 위한 조건입니다.
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

                    // 현재 처리 중인 방에서만 타이핑 표시를 보여줍니다.
                    if isCurrentProcessingRoom {
                        TypingBubbleView()
                            .transition(.opacity)
                    }

                    // 네트워크/파싱 오류 등은 화면 하단에 표시합니다.
                    if let errorMessage = roomViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    // 항상 스크롤할 수 있는 바닥 앵커를 둡니다.
                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorId)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 10)
            }
            .scrollDismissesKeyboard(.interactively)

            // 메시지가 없을 때는 안내 문구를 보여줍니다.
            .overlay {
                if roomViewModel.messages.isEmpty {
                    emptyNotice
                }
            }

            // 스크롤 정책
            // - 최초 진입: 바로 바닥으로
            // - 메시지 변화/타이핑 상태 변화: 자연스럽게 바닥으로 따라감
            // - 키보드 포커스 획득: 입력 중에도 최근 메시지가 보이게 바닥으로
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

    // “AI 답변 주의” 안내입니다.
    // - 제품 정책상 오답 가능성을 사용자에게 명시하고, 중요한 판단은 공식 자료 확인을 유도합니다.
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

    // 스크롤을 바닥 앵커로 이동합니다.
    // - 애니메이션 여부만 호출부에서 결정해, 이벤트 종류(초기/변화)에 따라 UX를 조정합니다.
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(bottomAnchorId, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottomAnchorId, anchor: .bottom)
        }
    }

    // 전송 중에는 입력을 막고, placeholder도 상태에 맞게 바꿉니다.
    private var placeholderText: String {
        alanCoordinator.isBusy ? "사용 중입니다" : "게임에 대해 질문하세요"
    }

    // 입력/전송 바입니다.
    // - TextField는 다중 라인(1...4)까지 허용하고, 전송 중에는 비활성화합니다.
    // - 전송 버튼은 빈 문자열/전송 중 상태에서 비활성화해 중복 전송을 막습니다.
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
