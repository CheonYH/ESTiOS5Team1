//
//  ChatRoomsView.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI

// 이 뷰는 “채팅방 목록 화면”입니다.
//
// 화면 책임
// - 기본 방(New Chat) 1개와 저장된 방 목록을 섹션으로 보여줍니다.
// - 방 선택, 편집(다중 선택), 삭제, 새 채팅 시작 같은 UI 이벤트를 ViewModel 정책과 연결합니다.
//
// 연동 구조
// - ChatRoomsViewModel
//   - rooms/defaultRoom/selectedRoomId/isEditing/selectedRoomIds 상태를 제공하고,
//     startNewConversation/delete/deleteSelectedRooms 같은 액션을 수행합니다.
// - onSelectRoom
//   - 상위 컨테이너(RootTabView 등)에게 “선택된 방이 바뀜”을 전달하는 콜백입니다.
//   - 이 뷰는 화면 전환 방식(내비게이션 push, split view, 시트 등)을 몰라도 되게 하고,
//     상위가 원하는 방식으로 ChatRoomView로 이동하도록 책임을 넘깁니다.
//
// 코드리뷰 포인트
// - 기본 방은 항상 유지: 사용자가 언제든 같은 진입점에서 새 대화를 시작할 수 있어 UX가 단순해집니다.
// - 편집 모드에서는 탭이 “선택 토글”로 바뀜: 실수로 방 전환되는 것을 막고, 삭제 대상 선택에 집중할 수 있습니다.
struct ChatRoomsView: View {
    @ObservedObject var roomsViewModel: ChatRoomsViewModel
    let onSelectRoom: (ChatRoom) -> Void

    var body: some View {
        NavigationStack {
            List {
                // 기본 방 섹션
                // - defaultRoom은 항상 존재하며, 현재 진행 중인 대화를 대표합니다.
                // - 편집 모드에서는 체크 표시를 보여주고, 일반 모드에서는 방 진입용 행으로 동작합니다.
                Section {
                    roomRow(
                        room: roomsViewModel.defaultRoom,
                        subtitle: "현재 대화중인 내용",
                        isChecked: roomsViewModel.selectedRoomIds.contains(roomsViewModel.defaultRoom.identifier),
                        isEditing: roomsViewModel.isEditing
                    ) {
                        handleTap(room: roomsViewModel.defaultRoom)
                    }
                } header: {
                    Text("새로운 대화")
                }

                // 저장된 방(아카이브) 섹션
                // - defaultRoom이 아닌 방만 표시합니다.
                // - 스와이프 삭제는 편집 모드가 아닐 때만 노출해, 다중 선택 삭제와 UX가 충돌하지 않게 합니다.
                Section {
                    ForEach(roomsViewModel.rooms.filter { $0.isDefaultRoom == false }) { room in
                        roomRow(
                            room: room,
                            subtitle: room.updatedAt.formatted(date: .abbreviated, time: .shortened),
                            isChecked: roomsViewModel.selectedRoomIds.contains(room.identifier),
                            isEditing: roomsViewModel.isEditing
                        ) {
                            handleTap(room: room)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if roomsViewModel.isEditing == false {
                                Button(role: .destructive) {
                                    // 삭제는 저장소(SwiftData actor)까지 연동되므로 async로 처리합니다.
                                    // - ViewModel이 방 레코드 삭제 + 메시지 삭제까지 수행합니다.
                                    Task { await roomsViewModel.delete(room: room) }
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text("저장된 대화")
                }
            }
            .navigationTitle("내 채팅목록")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            // 새 채팅 시작
                            // - ViewModel이 기본 방의 기존 메시지를 아카이브로 분리하고,
                            //   기본 방을 초기 상태로 리셋합니다(서버 문맥 분리용 clientId도 교체).
                            // - 이후 UI는 기본 방을 선택 상태로 만들고, 상위에게 선택 변경을 통지합니다.
                            await roomsViewModel.startNewConversation()
                            roomsViewModel.select(room: roomsViewModel.defaultRoom)
                            onSelectRoom(roomsViewModel.defaultRoom)
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("새 채팅 시작")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        // 편집 모드일 때만 일괄 삭제 버튼 노출
                        // - selectedRoomIds가 비어 있으면 비활성화해 “누르면 아무 일도 없음”을 방지합니다.
                        if roomsViewModel.isEditing {
                            Button(role: .destructive) {
                                Task { await roomsViewModel.deleteSelectedRooms() }
                            } label: {
                                Image(systemName: "trash")
                                    .frame(width: 44, alignment: .center)
                                    .foregroundStyle(Color(.systemRed))
                            }
                            .disabled(roomsViewModel.selectedRoomIds.isEmpty)
                        }

                        // 편집 토글
                        // - ViewModel이 선택 집합 초기화까지 책임져, 화면에 남은 체크 상태가 꼬이지 않게 합니다.
                        Button {
                            roomsViewModel.toggleEditing()
                        } label: {
                            Text(roomsViewModel.isEditing ? "확인" : "편집")
                        }
                    }
                }
            }
            .task {
                // 화면 표시 시 목록 갱신
                // - 저장소에서 최신 방 목록을 가져와 updatedAt 기준 정렬이 반영되게 합니다.
                await roomsViewModel.refreshRooms()
            }
        }
    }

    // 행 탭 처리
    // - 편집 모드: 선택 토글
    // - 일반 모드: 방 선택 후 상위에 전달하여 실제 화면 전환을 유도
    private func handleTap(room: ChatRoom) {
        if roomsViewModel.isEditing {
            roomsViewModel.toggleSelected(room: room)
            return
        }

        roomsViewModel.select(room: room)
        onSelectRoom(room)
    }

    // 방 목록의 공통 행 UI
    // - isEditing에 따라 왼쪽 아이콘을 체크 UI로 바꾸고, 오른쪽 chevron은 숨깁니다.
    // - Button으로 감싸 탭 영역을 확실히 하고, .plain 스타일로 리스트 기본 스타일 간섭을 줄입니다.
    @ViewBuilder
    private func roomRow(
        room: ChatRoom,
        subtitle: String,
        isChecked: Bool,
        isEditing: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isEditing {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .imageScale(.large)
                        .foregroundStyle(isChecked ? .blue : .secondary)
                } else {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(room.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isEditing == false {
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
