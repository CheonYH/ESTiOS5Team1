//
//  ChatRoomViewModel.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/9/26.
//

import Foundation
import Combine

// 이 ViewModel은 “한 채팅방 화면”의 상태와 전송 흐름을 담당합니다.
//
// 책임 범위
// - room/messages/inputText/errorMessage를 SwiftUI에 바인딩합니다.
// - sendMessage에서 입력 검증 → 게이트(MessageGate) → 프롬프트 구성(ChatbotPrompts) → 네트워크(AlanAPIClient)
//   → 저장(ChatSwiftDataStore) 순서로 실행합니다.
// - 동시 전송 제어는 AlanCoordinator에 위임합니다.
//
// 연동 위치
// - ChatRoomView: messages/inputText/errorMessage/isBusy(코디네이터) 기반으로 화면 렌더링
// - ChatSwiftDataStore(actor): 메시지 저장/로드 및 AES 암호화/Keychain 키 관리
// - AlanCoordinator: 한 번에 하나의 요청만 수행하도록 직렬화
// - MessageGate + TextClassifierAdapter(CoreML): 게임 질문만 서버로 보내도록 정책 보장
// - ChatbotPrompts/ChatTextProcessing: payload 포맷 고정 및 표시용 텍스트 정리
@MainActor
final class ChatRoomViewModel: ObservableObject {
    // 현재 표시 중인 방 메타데이터입니다.
    // - 방이 바뀌면 reload(room:)로 교체되고, 그 방의 메시지를 다시 로드합니다.
    @Published var room: ChatRoom

    // 현재 방의 메시지 목록입니다.
    // - commit/append를 통해 저장소에 반영한 뒤, 현재 방이면 UI 상태도 같이 갱신합니다.
    @Published var messages: [ChatMessage] = []

    // 입력창 바인딩 값입니다.
    // - sendMessage에서 trim 후 비우고(사용자 타이핑 UX), 메시지로 확정합니다.
    @Published var inputText: String = ""

    // 화면에 노출할 오류 메시지입니다.
    // - 설정 누락/URL 파싱 실패/네트워크 오류 등을 사용자가 이해 가능한 문자열로 표시합니다.
    @Published var errorMessage: String?

    // SwiftData 저장소(actor)입니다.
    // - ViewModel은 “저장/복원”만 호출하고, 암호화/AES/Keychain은 store 책임입니다.
    private let store: ChatSwiftDataStore

    // 전송 직렬화 코디네이터입니다.
    // - isBusy와 activeRoomId를 통해 UI에서 입력 비활성화/타이핑 표시를 제어합니다.
    private let alanCoordinator: AlanCoordinator

    // 테스트/디버그용 오버라이드입니다.
    // - SettingsModels(AppSettings)보다 우선 적용되어 서버/키를 빠르게 바꿀 수 있습니다.
    private let alanEndpointOverride: String?
    private let alanClientKeyOverride: String?

    // 서버 문맥 초기화(reset-state + system prompt)가 어떤 방 기준으로 완료됐는지 추적합니다.
    // - 방이 바뀌면 서버 문맥이 섞이지 않도록 ensureServerContextReadyIfNeeded에서 재초기화합니다.
    private var activeServerRoomIdentifier: UUID?

    // 방 전환 직후 첫 질문인지 표시합니다.
    // - 설정에서 includeLocalContext가 켜져 있으면, 첫 질문에만 로컬 요약을 붙여 과도한 프롬프트를 방지합니다.
    private var isFirstUserMessageAfterRoomSwitch: Bool = true

    // “게임 질문만 통과” 정책 게이트입니다.
    // - 비용/정책 측면에서 비게임 질문은 서버 호출 없이 즉시 차단 응답을 붙입니다.
    private let messageGate: MessageGate

    // 게임 질문 내부 의도 분류기입니다(공략/정보/추천).
    // - 분류 실패/신뢰도 낮음은 보수적으로 gameInfo로 폴백합니다.
    private let intentClassifier: MessageIntentClassifying?

    // 전송 도중 방이 아카이브되는 케이스(기본 방 → 새 방)에서,
    // “응답이 붙어야 하는 방”을 바꿔치기하기 위한 매핑입니다.
    // - ChatRoomsViewModel.startNewConversation() 같은 흐름에서 호출될 수 있습니다.
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

        // 도메인(게임/비게임) 분류기
        // - MessageGate는 “게임 전용 챗봇” 정책을 보장하기 위해 먼저 실행됩니다.
        let domainClassifier = CreateMLTextClassifierAdapter(modelName: "GameNonGame_bert")
        self.messageGate = MessageGate(
            config: MessageGateConfig(confidenceThreshold: 0.70),
            classifier: domainClassifier
        )

        // 게임 내부 의도 분류기(guide/info/recommend)
        // - 프롬프트의 [Intent] 섹션을 안정화해 응답 스타일을 일정하게 만듭니다.
        self.intentClassifier = CreateMLTextClassifierAdapter(modelName: "GameSort_bert")
    }

    // 방을 교체하고 메시지를 다시 로드합니다.
    // - UI에서 방 전환 시 호출되며, 첫 질문 플래그를 리셋합니다.
    func reload(room: ChatRoom) async {
        self.room = room
        messages = await store.loadMessages(roomIdentifier: room.identifier)
        isFirstUserMessageAfterRoomSwitch = true
    }

    // 최초 진입 시 메시지를 로드합니다.
    // - 화면이 켜질 때 1회 호출하는 용도입니다.
    func loadInitialMessages() async {
        messages = await store.loadMessages(roomIdentifier: room.identifier)
    }

    // “응답 귀속 방”을 바꾸기 위한 리다이렉트 등록입니다.
    // - 전송 시작 후 방이 이동되면, completion이 원래 방에 붙지 않게 targetRoomId로 전환합니다.
    func redirectCompletions(from sourceRoomId: UUID, to targetRoomId: UUID) {
        completionRedirect[sourceRoomId] = targetRoomId
    }

    // 입력을 확정하고 서버 호출(또는 차단 응답)을 수행합니다.
    //
    // 흐름 요약
    // 1) isBusy/빈 입력 방어
    // 2) 사용자 메시지를 먼저 append + 저장(commit)
    // 3) MessageGate로 비게임이면 즉시 차단 응답 추가
    // 4) Settings 로드 → endpoint/clientKey 검증
    // 5) AlanCoordinator.run으로 직렬화
    // 6) 방 단위 서버 문맥 초기화(reset-state + system prompt)
    // 7) intent 분류 → payload 구성(필요 시 local context summary 포함)
    // 8) ask 호출 → 표시 텍스트 정리 → 봇 메시지 append + 저장
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

        // 비게임 질문은 서버 호출 없이 즉시 응답을 붙입니다.
        // - UX상 “봇이 생각하는 시간”처럼 보이게 짧은 딜레이를 넣습니다.
        case .blockNonGame(_, let reply):
            await simulatedGateReplyDelay()
            let bot = ChatMessage(author: .bot, text: reply)

            let targetRoomId = resolveTargetRoomId(from: sourceRoomId)
            await append(bot, to: targetRoomId)

            completionRedirect[sourceRoomId] = nil
            return
        }

        let settings = AppSettings.load()

        // endpoint는 런타임 설정을 우선하고, 오버라이드가 있으면 최우선 적용합니다.
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

        // clientKey는 서버 문맥(client_id) 구분에 필요하므로 필수입니다.
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
                // 방이 바뀌면 서버 문맥을 리셋하고 system prompt를 1회 주입합니다.
                // - 이 단계가 없으면 다른 방 대화가 섞여 답변 품질이 흔들릴 수 있습니다.
                try await ensureServerContextReadyIfNeeded(
                    client: client,
                    clientId: clientIdText,
                    roomIdentifier: sourceRoomId
                )

                let intent = predictIntent(from: trimmedText)

                // 첫 질문 + 이전 대화가 있을 때만 요약을 포함합니다.
                // - 항상 포함하면 payload가 길어져 실패/품질 저하 가능성이 있어 제한합니다.
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

                // 서버 응답은 포맷이 흔들릴 수 있어, 표시 직전에 정리합니다.
                // - extractDisplayText: 따옴표로 감싼 문자열 형태 폴백
                // - TextCleaner.stripSourceMarkers: 출처 표기/잔여 토큰 제거
                let answerText = TextCleaner.stripSourceMarkers(extractDisplayText(from: rawAnswer))

                let bot = ChatMessage(author: .bot, text: answerText)

                // 전송 도중 방이 이동됐다면 응답은 targetRoomId로 저장합니다.
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

    // sourceRoomId에 대한 “응답 귀속 방”을 결정합니다.
    // - 리다이렉트가 없으면 원래 방으로 저장합니다.
    private func resolveTargetRoomId(from sourceRoomId: UUID) -> UUID {
        completionRedirect[sourceRoomId] ?? sourceRoomId
    }

    // 메시지 배열을 저장소에 반영하고, 현재 화면의 방이면 UI 상태도 같이 갱신합니다.
    // - saveMessages가 암호화/저장 수행
    // - touchRoomUpdatedAt으로 방 리스트 정렬(최근 대화)이 자연스럽게 갱신됩니다.
    private func commit(_ newMessages: [ChatMessage], to roomIdentifier: UUID) async {
        await store.saveMessages(newMessages, roomIdentifier: roomIdentifier)
        await store.touchRoomUpdatedAt(roomIdentifier: roomIdentifier)

        if room.identifier == roomIdentifier {
            messages = newMessages
        }
    }

    // 저장소에서 최신 메시지를 읽고 1개를 append한 뒤 commit합니다.
    // - 동시 저장이 있을 수 있어(방 이동/아카이브) 저장소 기준으로 다시 읽는 방식으로 일관성을 맞춥니다.
    private func append(_ message: ChatMessage, to roomIdentifier: UUID) async {
        let current = await store.loadMessages(roomIdentifier: roomIdentifier)
        let next = current + [message]
        await commit(next, to: roomIdentifier)
    }

    // MARK: - Alan Context

    // 방 단위로 서버 문맥을 준비합니다.
    //
    // 동작
    // - roomIdentifier가 이전과 다르면 reset-state로 서버 세션을 비우고
    // - systemPrompt를 1회 주입해 정책(게임 전용/intent 규칙)을 고정합니다.
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

    // 게임 질문 내부 의도 분류입니다.
    //
    // 정책
    // - 분류기 없으면 gameInfo 폴백
    // - confidence가 없으면(label만) inGameDomain이면 사용, 아니면 gameInfo
    // - confidence가 있으면 0.55 이상일 때만 inGameDomain label을 채택
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

    // 최근 메시지를 “User/Bot:” 라인 형태로 요약합니다.
    // - 프롬프트 길이 제한을 위해 messageCount와 maxCharacters로 상한을 둡니다.
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

    // 서버 응답이 따옴표로 감싼 문자열 형태로 올 때를 대비한 폴백입니다.
    // - 실제 JSON 파싱은 TextCleaner 쪽에서도 수행하지만, 여기서는 최소한의 표시 안정성만 확보합니다.
    private func extractDisplayText(from raw: String) -> String {
        if raw.hasPrefix("\""), raw.hasSuffix("\""), raw.count >= 2 {
            return String(raw.dropFirst().dropLast())
        }
        return raw
    }

    // 게이트 차단 응답에 “봇이 생각하는 시간”을 주기 위한 딜레이입니다.
    // - 실제 네트워크는 타지 않으므로 UX를 위해서만 존재합니다.
    private func simulatedGateReplyDelay() async {
        let seconds = Double.random(in: 1.0...2.0)
        let nanos = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanos)
    }
}
