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
    @Published var room: ChatRoom
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var errorMessage: String?

    private let store: ChatSwiftDataStore
    private let alanCoordinator: AlanCoordinator

    private let alanEndpointOverride: String?
    private let alanClientKeyOverride: String?

    private var activeServerRoomIdentifier: UUID?
    private var isFirstUserMessageAfterRoomSwitch: Bool = true

    private let messageGate: MessageGate
    private let intentClassifier: MessageIntentClassifying?

    private var completionRedirect: [UUID: UUID] = [:]

    init(
        room: ChatRoom,
        store: ChatSwiftDataStore,
        alanCoordinator: AlanCoordinator,
        alanEndpointOverride: String? = nil,
        alanClientKeyOverride: String? = nil
    ) {
        self.room = room
        self.store = store
        self.alanCoordinator = alanCoordinator
        self.alanEndpointOverride = alanEndpointOverride
        self.alanClientKeyOverride = alanClientKeyOverride

        let domainClassifier = CreateMLTextClassifierAdapter(modelName: "GameNonGame_bert")
        self.messageGate = MessageGate(
            config: MessageGateConfig(confidenceThreshold: 0.70),
            classifier: domainClassifier
        )

        self.intentClassifier = CreateMLTextClassifierAdapter(modelName: "GameSort_bert")
    }

    func reload(room: ChatRoom) async {
        self.room = room
        messages = await store.loadMessages(roomIdentifier: room.identifier)
        isFirstUserMessageAfterRoomSwitch = true
    }

    func loadInitialMessages() async {
        messages = await store.loadMessages(roomIdentifier: room.identifier)
    }

    func redirectCompletions(from sourceRoomId: UUID, to targetRoomId: UUID) {
        completionRedirect[sourceRoomId] = targetRoomId
    }

    func sendMessage() async {
        guard alanCoordinator.isBusy == false else { return }

        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false else { return }

        let sourceRoomId = room.identifier

        inputText = ""
        errorMessage = nil

        let guestMessage = ChatMessage(author: .guest, text: trimmedText)
        let before = messages
        let afterUserSend = before + [guestMessage]
        await commit(afterUserSend, to: sourceRoomId)

        switch messageGate.evaluate(trimmedText) {
        case .allowGame:
            break

        case .blockNonGame(_, let reply):
            await simulatedGateReplyDelay()
            let bot = ChatMessage(author: .bot, text: reply)

            let targetRoomId = resolveTargetRoomId(from: sourceRoomId)
            await append(bot, to: targetRoomId)

            completionRedirect[sourceRoomId] = nil
            return
        }

        let settings = AppSettings.load()

        let endpointText = (alanEndpointOverride ?? settings.alan.endpoint)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard endpointText.isEmpty == false else {
            if room.identifier == sourceRoomId { errorMessage = "ALAN ENDPOINT HOST IS MISSING" }
            completionRedirect[sourceRoomId] = nil
            return
        }

        guard let baseUrl = URL(string: endpointText) else {
            if room.identifier == sourceRoomId { errorMessage = "ALAN ENDPOINT HOST IS INVALID" }
            completionRedirect[sourceRoomId] = nil
            return
        }

        let clientIdText = (alanClientKeyOverride ?? settings.alan.clientKey)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard clientIdText.isEmpty == false else {
            if room.identifier == sourceRoomId { errorMessage = "ALAN CLIENT KEY IS MISSING" }
            completionRedirect[sourceRoomId] = nil
            return
        }

        let client = AlanAPIClient(configuration: .init(baseUrl: baseUrl))

        do {
            try await alanCoordinator.run(roomId: sourceRoomId) {
                try await ensureServerContextReadyIfNeeded(
                    client: client,
                    clientId: clientIdText,
                    roomIdentifier: sourceRoomId
                )

                let intent = predictIntent(from: trimmedText)

                let payload: String
                if settings.alan.includeLocalContext,
                   isFirstUserMessageAfterRoomSwitch,
                   before.isEmpty == false {
                    let summary = makeLocalContextSummary(
                        from: before,
                        messageCount: settings.alan.contextMessageCount,
                        maxCharacters: settings.alan.maxContextCharacters
                    )
                    payload = ChatbotPrompts.buildUserMessage(
                        intent: intent,
                        userText: trimmedText,
                        contextSummary: summary
                    )
                } else {
                    payload = ChatbotPrompts.buildUserMessage(
                        intent: intent,
                        userText: trimmedText
                    )
                }

                let rawAnswer = try await client.ask(content: payload, clientId: clientIdText)
                let answerText = TextCleaner.stripSourceMarkers(extractDisplayText(from: rawAnswer))

                let bot = ChatMessage(author: .bot, text: answerText)

                let targetRoomId = resolveTargetRoomId(from: sourceRoomId)
                await append(bot, to: targetRoomId)

                isFirstUserMessageAfterRoomSwitch = false
            }
        } catch {
            if room.identifier == sourceRoomId {
                errorMessage = error.localizedDescription
            }
        }

        completionRedirect[sourceRoomId] = nil
    }

    // MARK: - Persistence

    private func resolveTargetRoomId(from sourceRoomId: UUID) -> UUID {
        completionRedirect[sourceRoomId] ?? sourceRoomId
    }

    private func commit(_ newMessages: [ChatMessage], to roomIdentifier: UUID) async {
        await store.saveMessages(newMessages, roomIdentifier: roomIdentifier)
        await store.touchRoomUpdatedAt(roomIdentifier: roomIdentifier)

        if room.identifier == roomIdentifier {
            messages = newMessages
        }
    }

    private func append(_ message: ChatMessage, to roomIdentifier: UUID) async {
        let current = await store.loadMessages(roomIdentifier: roomIdentifier)
        let next = current + [message]
        await commit(next, to: roomIdentifier)
    }

    // MARK: - Alan Context

    private func ensureServerContextReadyIfNeeded(
        client: AlanAPIClient,
        clientId: String,
        roomIdentifier: UUID
    ) async throws {
        if activeServerRoomIdentifier == roomIdentifier { return }

        _ = try await client.resetState(clientId: clientId)
        _ = try await client.ask(content: ChatbotPrompts.systemPrompt, clientId: clientId)

        activeServerRoomIdentifier = roomIdentifier
        isFirstUserMessageAfterRoomSwitch = true
    }

    // MARK: - Helpers

    private func predictIntent(from text: String) -> GameIntentLabel {
        guard let prediction = intentClassifier?.predictLabel(text: text) else {
            return .gameInfo
        }

        let label = GameIntentLabel.fromModelLabel(prediction.label)

        if prediction.confidence < 0 {
            return label.isInGameDomain ? label : .gameInfo
        }

        if prediction.confidence >= 0.55, label.isInGameDomain {
            return label
        }

        return .gameInfo
    }

    private func makeLocalContextSummary(
        from messages: [ChatMessage],
        messageCount: Int,
        maxCharacters: Int
    ) -> String {
        let recent = messages.suffix(max(1, messageCount))
        let lines = recent.map { msg -> String in
            let role = (msg.author == .guest) ? "User" : "Bot"
            let content = msg.text.replacingOccurrences(of: "\n", with: " ")
            return "\(role): \(content)"
        }

        let joined = lines.joined(separator: "\n")
        if joined.count <= maxCharacters { return joined }
        return String(joined.prefix(maxCharacters))
    }

    private func extractDisplayText(from raw: String) -> String {
        if raw.hasPrefix("\""), raw.hasSuffix("\""), raw.count >= 2 {
            return String(raw.dropFirst().dropLast())
        }
        return raw
    }

    private func simulatedGateReplyDelay() async {
        let seconds = Double.random(in: 1.0...2.0)
        let nanos = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanos)
    }
}
