//
//  ChatRoomsView.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/9/26.
//

import SwiftUI

struct ChatRoomsView: View {
    @ObservedObject var roomsViewModel: ChatRoomsViewModel
    var onSelect: (ChatRoom) -> Void

    @State private var isPresentingAddRoom = false
    @State private var newRoomTitle: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(roomsViewModel.rooms) { room in
                    Button {
                        roomsViewModel.selectedRoomIdentifier = room.identifier
                        onSelect(room)
                    } label: {
                        HStack {
                            Text(room.title)
                            Spacer()
                            if roomsViewModel.selectedRoomIdentifier == room.identifier {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                    .swipeActions {
                        if room.isDefaultRoom == false {
                            Button(role: .destructive) {
                                Task { await roomsViewModel.deleteRoom(roomIdentifier: room.identifier) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rooms")
            .overlay(alignment: .bottomTrailing) {
                Button {
                    isPresentingAddRoom = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .padding(16)
                }
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .padding()
            }
            .sheet(isPresented: $isPresentingAddRoom) {
                addRoomSheet
            }
        }
    }

    private var addRoomSheet: some View {
        NavigationStack {
            Form {
                TextField("Room title", text: $newRoomTitle)
                Button("Create") {
                    let titleValue = newRoomTitle
                    newRoomTitle = ""
                    isPresentingAddRoom = false
                    Task { await roomsViewModel.addRoom(title: titleValue) }
                }
            }
            .navigationTitle("New Room")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { isPresentingAddRoom = false }
                }
            }
        }
    }
}
