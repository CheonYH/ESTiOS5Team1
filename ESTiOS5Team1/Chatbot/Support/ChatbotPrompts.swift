//
//  ChatbotPrompts.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/28/26.
//

import Foundation

enum ChatbotPrompts {

    typealias Intent = GameIntentLabel

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

    static func buildUserMessage(intent: Intent, userText: String) -> String {
        let cleanedUserText = userText.trimmingCharacters(in: .whitespacesAndNewlines)

        return """
        [Intent]
        \(intent.rawValue)

        [User]
        \(cleanedUserText)
        """
    }

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

    static func defaultNonGameReply() -> String {
        "죄송하지만, 현재 요청은 제가 처리할 수 있는 범위를 벗어납니다. 저는 비디오 게임에 대한 정보 제공에 특화되어 있습니다. 비디오 게임 관련 질문이 있으시면 언제든지 도와드리겠습니다!"
    }
}
