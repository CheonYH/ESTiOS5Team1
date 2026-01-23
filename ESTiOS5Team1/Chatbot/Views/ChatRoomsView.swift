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
                        title: roomsViewModel.defaultRoom.title,
                        subtitle: "Current conversation",
                        isSelected: roomsViewModel.selectedRoomIds.contains(roomsViewModel.defaultRoom.identifier),
                        isEditing: roomsViewModel.isEditing
                    ) {
                        if roomsViewModel.isEditing {
                            roomsViewModel.toggleSelected(room: roomsViewModel.defaultRoom)
                        } else {
                            roomsViewModel.select(room: roomsViewModel.defaultRoom)
                            onSelectRoom(roomsViewModel.defaultRoom)
                        }
                    }
                } header: {
                    Text("New Chat")
                }

                Section {
                    ForEach(roomsViewModel.rooms.filter { $0.isDefaultRoom == false }) { room in
                        roomRow(
                            title: room.title,
                            subtitle: room.updatedAt.formatted(date: .abbreviated, time: .shortened),
                            isSelected: roomsViewModel.selectedRoomIds.contains(room.identifier),
                            isEditing: roomsViewModel.isEditing
                        ) {
                            if roomsViewModel.isEditing {
                                roomsViewModel.toggleSelected(room: room)
                            } else {
                                roomsViewModel.select(room: room)
                                onSelectRoom(room)
                            }
                        }
                    }
                } header: {
                    Text("Archive")
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await roomsViewModel.startNewConversation() }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Start new chat")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if roomsViewModel.isEditing {
                            Button(role: .destructive) {
                                Task { await roomsViewModel.deleteSelectedRooms() }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .disabled(roomsViewModel.selectedRoomIds.isEmpty)
                        }

                        Button {
                            roomsViewModel.toggleEditing()
                        } label: {
                            Text(roomsViewModel.isEditing ? "Done" : "Edit")
                        }
                    }
                }
            }
            .task {
                await roomsViewModel.refreshRooms()
            }
        }
    }

    @ViewBuilder
    private func roomRow(
        title: String,
        subtitle: String,
        isSelected: Bool,
        isEditing: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .imageScale(.large)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                } else {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
