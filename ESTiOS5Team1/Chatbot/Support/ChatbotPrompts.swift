//
//  ChatbotPrompts.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/28/26.
//

import Foundation

enum ChatbotPrompts {

    // Intent 라벨을 문자열로 직접 비교하지 않고 enum으로 다룬다. 모델 출력은 결국 문자열이지만, 앱 내부에서는 enum으로 변환해 사용하는 편이 안전하다.
    typealias Intent = GameIntentLabel

    // 시스템 프롬프트는 "게임 관련만 답변"을 강하게 고정한다.
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

    // 기본적으로 서버에 보내는 메시지 포맷을 한 군데에서 관리한다.
    static func buildUserMessage(intent: Intent, userText: String) -> String {
        let cleanedUserText = userText.trimmingCharacters(in: .whitespacesAndNewlines)

        return """
        [Intent]
        \(intent.rawValue)

        [User]
        \(cleanedUserText)
        """
    }

    // 대화 요약을 함께 보내야 하는 구조라면 이 포맷을 사용한다.
    // GET만 받는 구조에서는 길이 제한에 걸릴 수 있으니, 길이를 제한한다.
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

    // non-game 차단 시 앱에서 쓸 기본 문구(게이트/서버 거부 공통 톤)
    static func defaultNonGameReply() -> String {
        "죄송하지만, 현재 요청은 제가 처리할 수 있는 범위를 벗어납니다. 저는 비디오 게임에 대한 정보 제공에 특화되어 있습니다. 비디오 게임 관련 질문이 있으시면 언제든지 도와드리겠습니다!"
    }
}
