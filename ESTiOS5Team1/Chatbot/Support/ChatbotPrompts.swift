//
//  ChatbotPrompts.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/28/26.
//

import Foundation

// MARK: - Overview

/// 서버(모델)에게 전달할 프롬프트 템플릿을 한 곳에서 관리합니다.
///
/// 이 파일의 역할
/// - system prompt(역할/규칙)를 고정해 “게임 전용 챗봇” 컨셉을 서버 측에 명확히 전달합니다.
/// - user message payload를 일정한 포맷([Intent], [User], [Context Summary])으로 구성해 응답 품질을 안정화합니다.
///
/// 연동 위치
/// - ChatRoomViewModel: intent 분류 결과(GameIntentLabel)와 사용자 입력을 조합해 buildUserMessage로 payload를 만들고,
///   AlanAPIClient.ask로 전송합니다.
/// - MessageGate: 게임 외 질문은 네트워크 호출 없이 defaultNonGameReply로 차단 응답을 만듭니다.
///
/// 구현 선택 이유
/// - 프롬프트 포맷/문구는 제품 정책에 가깝기 때문에, ViewModel에서 분산 관리하지 않고 한 파일로 모읍니다.
/// - 섹션 헤더를 명시하면 모델이 입력의 “의도/문맥/질문”을 구분하기 쉬워집니다.
enum ChatbotPrompts {

    /// 앱 내부 의도 라벨의 별칭입니다.
    ///
    /// intent 타입을 여기서 고정해두면, 프롬프트 조립 로직이 특정 enum 이름에 과하게 의존하지 않습니다.
    typealias Intent = GameIntentLabel

    /// 서버 측 대화 규칙을 고정하는 system prompt입니다.
    ///
    /// 사용 목적
    /// - 게임 관련 질문만 답하게 만들고, 비게임 질문은 거절하도록 정책을 박습니다.
    /// - “Intent 라벨을 따르라”는 규칙을 넣어, 분류 결과에 맞는 답변 스타일을 유도합니다.
    ///
    /// 연동 방식
    /// - ChatRoomViewModel이 방 전환/새 채팅 시점에 resetState 이후 1회 주입하는 흐름으로 사용됩니다.
    static let systemPrompt: String = """
    You are a specialized Game Assistant called "게임봇".
    You are focused exclusively on video games.

    Rules:
    - Only answer video-game related requests.
    - If the request is not about video games, refuse with a short apology and ask for a game-related question.
    - Do not fabricate. If unsure, say you are unsure.
    - Match the user’s language (Korean/English).

    Intent:
    - The user message includes [Intent] label.
    - Follow it strictly:
      - game_guide: step-by-step actionable guidance.
      - game_info: concise explanations/definitions.
      - game_recommend: 3-5 recommendations, keep it practical.
      - non_game: refuse.
    """

    /// 기본 요청 payload를 구성합니다.
    ///
    /// 포맷을 고정하는 이유
    /// - 모델이 입력을 구조적으로 해석하기 쉬워져 답변 품질이 흔들리지 않습니다.
    /// - intent를 별도 헤더로 분리하면, 사용자 원문만 보고 스타일이 바뀌는 것을 줄입니다.
    static func buildUserMessage(intent: Intent, userText: String) -> String {
        let cleanedUserText = userText.trimmingCharacters(in: .whitespacesAndNewlines)

        return """
        [Intent]
        \(intent.rawValue)

        [User]
        \(cleanedUserText)
        """
    }

    /// 로컬 대화 요약을 포함한 요청 payload를 구성합니다.
    ///
    /// contextSummary는 “최근 대화의 핵심”만 전달하기 위한 보조 정보입니다.
    /// - ChatRoomViewModel에서 설정(AppSettings.alan.includeLocalContext)이 켜져 있고,
    ///   특정 조건(예: 방 전환 직후 첫 질문 등)일 때만 포함시키는 방식으로 사용됩니다.
    ///
    /// 빈 summary면 기본 buildUserMessage로 폴백합니다.
    static func buildUserMessage(intent: Intent, userText: String, contextSummary: String) -> String {
        let cleanedUserText = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedSummary = contextSummary.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedSummary.isEmpty {
            return buildUserMessage(intent: intent, userText: cleanedUserText)
        }

        return """
        [Intent]
        \(intent.rawValue)

        [Context Summary]
        \(cleanedSummary)

        [User]
        \(cleanedUserText)
        """
    }

    /// 게임 외 질문 차단 시 사용할 기본 응답입니다.
    ///
    /// 네트워크 호출을 하지 않고 즉시 반환할 때 사용합니다.
    /// - MessageGate가 allow가 아닌 결정을 내리면, ViewModel이 이 문구를 봇 메시지로 append합니다.
    static func defaultNonGameReply() -> String {
        "죄송하지만, 현재 요청은 제가 처리할 수 있는 범위를 벗어납니다. 저는 비디오 게임에 대한 정보 제공에 특화되어 있습니다. 비디오 게임 관련 질문이 있으시면 언제든지 도와드리겠습니다!"
    }
}
