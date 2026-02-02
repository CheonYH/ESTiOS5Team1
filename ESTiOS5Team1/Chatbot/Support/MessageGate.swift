//
//  MessageGate.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/22/26.
//

import Foundation

enum MessageGateDecision: Equatable {
    case allowGame
    case blockNonGame(reason: MessageGateBlockReason, reply: String)
}

enum MessageGateBlockReason: Equatable {
    case promptInjection
    case secretRequest
    case profanity
    case nonGame
}

protocol MessageIntentClassifying {
    func predictLabel(text: String) -> (label: String, confidence: Double)?
}

struct MessageGateConfig: Equatable {
    var confidenceThreshold: Double = 0.70
    var treatMissingConfidenceAsHigh: Bool = true
}

struct MessageGate {

    private let config: MessageGateConfig
    private let classifier: MessageIntentClassifying?

    init(
        config: MessageGateConfig = MessageGateConfig(),
        classifier: MessageIntentClassifying? = nil
    ) {
        self.config = config
        self.classifier = classifier
    }

    func evaluate(_ rawText: String) -> MessageGateDecision {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard text.isEmpty == false else {
            return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
        }

        if containsPromptInjection(text) {
            return .blockNonGame(reason: .promptInjection, reply: Self.defaultInjectionReply())
        }

        if containsSecretRequest(text) {
            return .blockNonGame(reason: .secretRequest, reply: Self.defaultSecretReply())
        }

        if containsProfanity(text) {
            return .blockNonGame(reason: .profanity, reply: Self.defaultProfanityReply())
        }

        if looksGameByHeuristic(text) {
            return .allowGame
        }

        guard let prediction = classifier?.predictLabel(text: text) else {
            return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
        }

        let domain = GameDomainLabel.fromModelLabel(prediction.label)
        let confidence = prediction.confidence

        let hasUsableConfidence = confidence >= 0
        if hasUsableConfidence == false, config.treatMissingConfidenceAsHigh {
            if domain.isGame { return .allowGame }
            return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
        }

        if domain.isGame, confidence >= config.confidenceThreshold {
            return .allowGame
        }

        if domain.isNonGameOrUnknown, confidence >= config.confidenceThreshold {
            return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
        }

        return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
    }

    private func containsPromptInjection(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let patterns = [
            "ignore previous",
            "system prompt",
            "reveal prompt",
            "jailbreak",
            "이전 지침 무시",
            "시스템 프롬프트",
            "프롬프트 공개"
        ]
        return patterns.contains { lowered.contains($0) }
    }

    private func containsSecretRequest(_ text: String) -> Bool {
        let lowered = text.lowercased()

        let englishPatterns = [
            #"\bapi[-_ ]?key\b"#,
            #"\bclient[-_ ]?key\b"#,
            #"\btoken\b"#,
            #"\bpassword\b"#,
            #"\bsecret\b"#
        ]
        if matchesAny(lowered, patterns: englishPatterns) {
            return true
        }

        let koreanHighSignal = [
            "비밀번호",
            "토큰",
            "시크릿",
            "apikey",
            "api키",
            "api 키",
            "클라이언트키",
            "클라이언트 키"
        ]
        if koreanHighSignal.contains(where: { lowered.contains($0) }) {
            return true
        }

        let koreanContextual = [
            "키 알려",
            "키 줘",
            "키 보여",
            "키 값",
            "토큰 값",
            "토큰 알려",
            "비번 알려",
            "비번 줘"
        ]
        if koreanContextual.contains(where: { lowered.contains($0) }) {
            return true
        }

        return false
    }

    private func containsProfanity(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let patterns = [
            "ㅅㅂ",
            "ㅂㅅ",
            "씨발",
            "fuck",
            "shit",
            "bitch"
        ]
        return patterns.contains { lowered.contains($0) }
    }

    private func looksGameByHeuristic(_ text: String) -> Bool {
        let lowered = text.lowercased()

        let gameTokens = [
            "공략",
            "빌드",
            "메타",
            "보스",
            "스킬",
            "퀘스트",
            "파밍",
            "장비",
            "레벨",
            "랭크",
            "dps",
            "fps",
            "build",
            "walkthrough",
            "quest",
            "boss"
        ]

        return gameTokens.contains { lowered.contains($0) }
    }

    private func matchesAny(_ text: String, patterns: [String]) -> Bool {
        patterns.contains { pattern in
            text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    static func defaultNonGameReply() -> String {
        "죄송하지만, 현재 요청은 제가 처리할 수 있는 범위를 벗어납니다. 저는 비디오 게임에 대한 정보 제공에 특화되어 있습니다. 비디오 게임 관련 질문이 있으시면 언제든지 도와드리겠습니다!"
    }

    static func defaultInjectionReply() -> String {
        "요청하신 내용은 보안상 처리할 수 없습니다. 게임 관련 질문으로 도와드릴게요."
    }

    static func defaultSecretReply() -> String {
        "보안상 민감한 정보(키/토큰/비밀번호 등)는 제공할 수 없습니다. 게임 관련 질문으로 도와드릴게요."
    }

    static func defaultProfanityReply() -> String {
        "표현을 조금만 순화해주시면 게임 관련 질문으로 도와드릴게요."
    }
}
