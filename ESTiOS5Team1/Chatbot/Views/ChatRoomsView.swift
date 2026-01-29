//
//  ChatRoomsView.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/13/26.
//

import SwiftUI

struct ChatRoomsView: View {
    @ObservedObject var roomsViewModel: ChatRoomsViewModel
    let onSelectRoom: (ChatRoom) -> Void

    var body: some View {
        NavigationStack {
            List {
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

                        Button {
                            roomsViewModel.toggleEditing()
                        } label: {
                            Text(roomsViewModel.isEditing ? "확인" : "편집")
                        }
                    }
                }
            }
            .task {
                await roomsViewModel.refreshRooms()
            }
        }
    }

    private func handleTap(room: ChatRoom) {
        if roomsViewModel.isEditing {
            roomsViewModel.toggleSelected(room: room)
            return
        }

        roomsViewModel.select(room: room)
        onSelectRoom(room)
    }

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
