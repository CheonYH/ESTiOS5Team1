//
//  ChatRoomViewModel.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/9/26.
//

import Foundation
import Combine

@MainActor
final class ChatRoomViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published var composerText: String = ""
    @Published private(set) var isSending: Bool = false
    @Published private(set) var errorMessage: String?

    private let store: ChatLocalStore
    private let alanClient: AlanAPIClient
    private let settingsProvider: () -> AppSettings

    private(set) var room: ChatRoom

    init(
        room: ChatRoom,
        store: ChatLocalStore,
        alanClient: AlanAPIClient,
        settingsProvider: @escaping () -> AppSettings
    ) {
        self.room = room
        self.store = store
        self.alanClient = alanClient
        self.settingsProvider = settingsProvider
    }

    func reload(room: ChatRoom) async {
        self.room = room
        messages = await store.loadMessages(roomIdentifier: room.identifier)
    }

    func load() async {
        messages = await store.loadMessages(roomIdentifier: room.identifier)
    }

    func sendGuestMessage() async {
        let trimmedText = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        composerText = ""
        errorMessage = nil
        isSending = true

        let guestMessage = ChatMessage(author: .guest, text: trimmedText)
        messages.append(guestMessage)
        await store.saveMessages(messages, roomIdentifier: room.identifier)

        let settings = settingsProvider()
        guard settings.alan.isEnabled else {
            isSending = false
            return
        }

        do {
            let answerText = try await alanClient.ask(
                apiKey: settings.alan.apiKey,
                endpoint: settings.alan.endpoint,
                authHeaderField: settings.alan.authHeaderField.isEmpty ? nil : settings.alan.authHeaderField,
                authHeaderPrefix: settings.alan.authHeaderPrefix.isEmpty ? nil : settings.alan.authHeaderPrefix,
                clientIdentifier: room.alanClientIdentifier,
                content: trimmedText
            )

            let botMessage = ChatMessage(author: .bot, text: answerText)
            messages.append(botMessage)
            await store.saveMessages(messages, roomIdentifier: room.identifier)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }
}
