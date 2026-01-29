//
//  MessageGate.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/22/26.
//

import Foundation

// 외부로 노출되는 판정 결과 타입
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

// 모델 분류기 인터페이스
// label은 모델 출력 문자열 그대로, confidence는 모델이 확률을 제공하면 0~1로, 없으면 음수로 전달한다.
protocol MessageIntentClassifying {
    func predictLabel(text: String) -> (label: String, confidence: Double)?
}

// 게이트 정책 설정
// 도메인 라벨 문자열을 직접 비교하지 않도록, 모델 출력은 enum으로 변환해 처리한다.
struct MessageGateConfig: Equatable {
    var confidenceThreshold: Double = 0.70

    // confidence가 의미 없거나 제공되지 않는 모델을 사용할 때(예: typed 모델) 라벨만으로 판정할지 여부
    // true면 confidence가 음수일 때 threshold 검사를 생략한다.
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

        // 입력이 비어 있으면 게임 질문으로 볼 수 없으므로 차단한다.
        guard text.isEmpty == false else {
            return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
        }

        // 간단한 보안/품질 필터는 ML 이전에 처리한다.
        // 의도가 명확한 차단 사유는 곧바로 종료한다.
        if containsPromptInjection(text) {
            return .blockNonGame(reason: .promptInjection, reply: Self.defaultInjectionReply())
        }

        if containsSecretRequest(text) {
            return .blockNonGame(reason: .secretRequest, reply: Self.defaultSecretReply())
        }

        if containsProfanity(text) {
            return .blockNonGame(reason: .profanity, reply: Self.defaultProfanityReply())
        }

        // 게임 관련 토큰이 아주 명확하면 ML 없이 통과시킨다.
        // 분류기가 없거나 실패했을 때 사용자 경험을 유지하기 위한 보조 장치다.
        if looksGameByHeuristic(text) {
            return .allowGame
        }

        // ML 분류가 없으면 기본적으로 차단한다.
        guard let prediction = classifier?.predictLabel(text: text) else {
            return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
        }

        // 모델이 내보내는 문자열 라벨을 enum으로 변환해 앱 내부에서 안전하게 처리한다.
        let domain = GameDomainLabel.fromModelLabel(prediction.label)
        let confidence = prediction.confidence

        // confidence가 제공되지 않거나 의미가 없을 때(음수)는 라벨만으로 처리한다.
        let hasUsableConfidence = confidence >= 0
        if hasUsableConfidence == false, config.treatMissingConfidenceAsHigh {
            if domain.isGame { return .allowGame }
            return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
        }

        // confidence가 유효하면 threshold를 반영한다.
        if domain.isGame, confidence >= config.confidenceThreshold {
            return .allowGame
        }

        if domain.isNonGameOrUnknown, confidence >= config.confidenceThreshold {
            return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
        }

        // confidence가 낮으면 게임 질문으로 보기 어렵다고 판단하고 차단한다.
        return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
    }

    // 프롬프트 인젝션은 키워드 기반의 매우 단순한 방어선이다.
    // 과도하게 공격적인 필터는 정상 질문을 막을 수 있으므로 최소한의 패턴만 둔다.
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

    // 민감정보 요청은 부분 문자열 contains만으로 처리하면 오탐이 많다.
    // 영어권 키워드는 단어 경계를 포함한 정규식으로, 한국어는 요청 의도가 드러나는 표현 중심으로 처리한다.
    private func containsSecretRequest(_ text: String) -> Bool {
        let lowered = text.lowercased()

        // 영어 키워드: 단어 경계를 사용해 "tokenizer" 같은 정상 단어 오탐을 줄인다.
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

        // 한국어 고신호 키워드: 단어 자체가 민감정보 맥락일 가능성이 높다.
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

        // 한국어 저신호 단어(예: "키")는 오탐이 많아서, 요청 의도가 드러나는 표현에서만 차단한다.
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

    // 게이트를 너무 엄격하게 만들면 “게임 질문인데도 차단”이 자주 발생한다.
    // 그래서 게임 토큰이 명확한 경우에는 통과시키는 완충 구간을 둔다.
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
