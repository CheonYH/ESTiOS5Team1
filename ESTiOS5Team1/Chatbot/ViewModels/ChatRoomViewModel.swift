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
    @Published var isSending: Bool = false
    @Published var errorMessage: String?

    private let store: ChatSwiftDataStore

    // Preview에서만 강제 주입
    private let alanEndpointOverride: String?
    private let alanClientKeyOverride: String?

    // 서버 문맥이 현재 어느 방인지(로컬 기준) 기록
    private var activeServerRoomIdentifier: UUID?

    // 방 전환 직후 "첫 메시지"에서만 context 요약을 붙이고 싶을 때 사용
    private var isFirstUserMessageAfterRoomSwitch: Bool = true

    // 게임/비게임 게이트
    private let messageGate: MessageGate

    // 게임 인텐트 분류기(공략/정보/추천 등)
    private let intentClassifier: MessageIntentClassifying?

    init(
        room: ChatRoom,
        store: ChatSwiftDataStore,
        alanEndpointOverride: String? = nil,
        alanClientKeyOverride: String? = nil
    ) {
        self.room = room
        self.store = store
        self.alanEndpointOverride = alanEndpointOverride
        self.alanClientKeyOverride = alanClientKeyOverride

        // 1차 필터: 휴리스틱 + ML 분류로 Non-Game 차단
        let domainClassifier = CreateMLTextClassifierAdapter(modelName: "GameNonGame_bert")
        self.messageGate = MessageGate(
            config: MessageGateConfig(confidenceThreshold: 0.70),
            classifier: domainClassifier
        )

        // 2차 분류: 게임 도메인 내부 인텐트 분류
        // typed 모델은 확률이 없을 수 있어 confidence는 -1로 내려오며, 그 경우 라벨만으로 처리한다.
        self.intentClassifier = CreateMLTextClassifierAdapter(modelName: "GameSort_bert")
    }

    func reload(room: ChatRoom) async {
        self.room = room
        messages = await store.loadMessages(roomIdentifier: room.identifier)

        // 방 전환: 다음 전송 시 reset + system 주입 + first-message-context 허용
        isFirstUserMessageAfterRoomSwitch = true
    }

    func loadInitialMessages() async {
        messages = await store.loadMessages(roomIdentifier: room.identifier)
    }

    func sendMessage() async {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false else { return }
        guard isSending == false else { return }

        inputText = ""
        errorMessage = nil
        isSending = true
        defer { isSending = false }

        // 전송 직전의 메시지 스냅샷(요약용)
        let messagesBeforeSending = messages

        // 사용자 메시지 저장/표시
        let guestMessage = ChatMessage(author: .guest, text: trimmedText)
        messages.append(guestMessage)
        await store.saveMessages(messages, roomIdentifier: room.identifier)
        await store.touchRoomUpdatedAt(roomIdentifier: room.identifier)

        // 1) 게이트: 게임이 아니면 Alan 호출 없이 차단
        switch messageGate.evaluate(trimmedText) {
        case .allowGame:
            break

        case .blockNonGame(_, let reply):
            await simulatedGateReplyDelay()

            let botMessage = ChatMessage(author: .bot, text: reply)
            messages.append(botMessage)
            await store.saveMessages(messages, roomIdentifier: room.identifier)
            await store.touchRoomUpdatedAt(roomIdentifier: room.identifier)
            return
        }

        // 2) 설정 로드 (Preview override가 있으면 우선)
        let settings = AppSettings.load()

        let endpointText = (alanEndpointOverride ?? settings.alan.endpoint)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard endpointText.isEmpty == false else {
            errorMessage = "ALAN ENDPOINT HOST IS MISSING"
            return
        }

        guard let baseUrl = URL(string: endpointText) else {
            errorMessage = "ALAN ENDPOINT HOST IS INVALID"
            return
        }

        // 기존 프로젝트는 clientKey를 서버 client_id로 사용하고 있다.
        // 방별 client_id를 쓰도록 바꾸려면 서버 설계와 함께 정리해야 하므로, 현재는 기존 규칙을 유지한다.
        let clientIdText = (alanClientKeyOverride ?? settings.alan.clientKey)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard clientIdText.isEmpty == false else {
            errorMessage = "ALAN CLIENT KEY IS MISSING"
            return
        }

        let client = AlanAPIClient(configuration: .init(baseUrl: baseUrl))

        do {
            // 3) 방 전환 감지 시: reset-state -> system prompt 주입
            try await ensureServerContextReadyIfNeeded(
                client: client,
                clientId: clientIdText
            )

            // 4) 인텐트 분류(공략/정보/추천)
            let intent = predictIntent(from: trimmedText)

            // 5) payload 구성
            // 방 전환 후 첫 메시지이고, 해당 방에 과거 대화가 있을 때만 context 요약을 붙인다.
            // GET 요청 길이 제한이 있으니, 설정 기반으로 길이를 제한한다.
            let payload: String
            if settings.alan.includeLocalContext,
               isFirstUserMessageAfterRoomSwitch,
               messagesBeforeSending.isEmpty == false {
                let summary = makeLocalContextSummary(
                    from: messagesBeforeSending,
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

            let botMessage = ChatMessage(author: .bot, text: answerText)
            messages.append(botMessage)
            await store.saveMessages(messages, roomIdentifier: room.identifier)
            await store.touchRoomUpdatedAt(roomIdentifier: room.identifier)

            // 이제부터는 user만 보냄
            isFirstUserMessageAfterRoomSwitch = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // 방 전환 시 서버 문맥을 초기화하고 시스템 프롬프트를 주입한다.
    // 같은 방에서 계속 대화할 때는 불필요한 reset을 하지 않도록 activeServerRoomIdentifier로 막는다.
    private func ensureServerContextReadyIfNeeded(
        client: AlanAPIClient,
        clientId: String
    ) async throws {
        if activeServerRoomIdentifier == room.identifier { return }

        _ = try await client.resetState(clientId: clientId)

        // 시스템 프롬프트는 UI에 표시하지 않는다.
        _ = try await client.ask(content: ChatbotPrompts.systemPrompt, clientId: clientId)

        activeServerRoomIdentifier = room.identifier
        isFirstUserMessageAfterRoomSwitch = true
    }

    // 인텐트 분류가 실패하면 정보형으로 처리한다.
    // 게임 분류 자체는 MessageGate에서 이미 통과한 상태라는 전제다.
    private func predictIntent(from text: String) -> GameIntentLabel {
        guard let prediction = intentClassifier?.predictLabel(text: text) else {
            return .gameInfo
        }

        let label = GameIntentLabel.fromModelLabel(prediction.label)

        // typed 모델은 confidence가 -1로 내려올 수 있다.
        // confidence가 유효하지 않으면 라벨만 신뢰한다.
        if prediction.confidence < 0 {
            return label.isInGameDomain ? label : .gameInfo
        }

        // confidence가 존재하는 모델이면 임계값을 반영할 수 있다.
        // 지금은 인텐트 분류에서는 보수적으로 처리하고, 애매하면 정보형으로 둔다.
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

    // 서버가 따옴표로 감싼 문자열을 주는 경우가 있어 표시용으로만 정리한다.
    private func extractDisplayText(from raw: String) -> String {
        if raw.hasPrefix("\""), raw.hasSuffix("\""), raw.count >= 2 {
            return String(raw.dropFirst().dropLast())
        }
        return raw
    }

    // 자동답변에도 딜레이를 주어 AI가 작동한 것처럼 느껴지도록 한다.
    private func simulatedGateReplyDelay() async {
        let seconds = Double.random(in: 1.0...2.0)
        let nanos = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanos)
    }
}
