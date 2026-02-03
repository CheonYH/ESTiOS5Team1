//
//  MessageGate.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/22/26.
//

import Foundation

// MARK: - Overview

// 사용자 입력을 서버로 보내기 전에 1차 필터링을 수행하는 게이트입니다.
//
// 이 파일의 역할
// - 게임 전용 챗봇 정책을 클라이언트에서 먼저 보장합니다.
// - 비용 절감: 불필요한 네트워크 호출을 줄입니다.
// - 안전성: 프롬프트 인젝션/민감정보 요청/욕설을 서버 호출 전에 차단합니다.
//
// 연동 위치
// - ChatRoomViewModel: sendMessage 흐름에서 입력 직후 evaluate로 allow/block를 결정합니다.
// - ChatbotPrompts: block일 때 안내 문구를 봇 메시지로 즉시 반환하는 흐름과 연결됩니다.
// - TextClassifierAdapter: classifier 구현체가 CoreML 모델을 감싸서 label/confidence를 제공합니다.
// - ChatModels.GameDomainLabel: 모델 라벨 문자열을 앱 내부 표준(game/non_game/unknown)으로 정규화합니다.
//
// 구현 선택 이유
// - "가벼운 규칙"을 먼저 적용하고, 마지막에만 ML 분류기를 호출해 성능을 지킵니다.
// - unknown/신뢰도 낮은 결과는 보수적으로 차단해 제품 컨셉을 흔들리지 않게 합니다.

// MARK: - Decision

/// 게이트 판단 결과입니다.
///
/// allowGame
/// - 입력을 게임 관련 질문으로 보고, 서버 호출을 진행합니다.
///
/// blockNonGame
/// - 서버 호출 없이 reply를 바로 반환합니다.
/// - reason을 함께 남겨, 로그/정책 개선 시 근거로 사용할 수 있습니다.
enum MessageGateDecision: Equatable {
    case allowGame
    case blockNonGame(reason: MessageGateBlockReason, reply: String)
}

/// 차단 사유를 구분합니다.
///
/// reason을 분리한 이유
/// - UI에 직접 노출하지 않아도, 어떤 정책에 걸렸는지 추적하기 쉽습니다.
/// - 추후 “차단 메시지 문구/정책”을 사유별로 조정할 수 있습니다.
enum MessageGateBlockReason: Equatable {
    case promptInjection
    case secretRequest
    case profanity
    case nonGame
}

// MARK: - Classifier Contract

/// 메시지 분류기 어댑터 계약입니다.
///
/// 이 프로토콜이 필요한 이유
/// - MessageGate는 “분류 결과만” 필요하고, CoreML/다른 엔진 구현 상세는 몰라도 됩니다.
/// - 테스트에서는 더미 분류기를 주입해 정책 로직만 검증할 수 있습니다.
///
/// 반환값
/// - label: 모델이 예측한 문자열 라벨
/// - confidence: 확률(없으면 -1 같은 값으로 표현 가능)
protocol MessageIntentClassifying {
    func predictLabel(text: String) -> (label: String, confidence: Double)?
}

// MARK: - Config

/// 게이트 동작 파라미터입니다.
///
/// confidenceThreshold
/// - 모델 결과를 신뢰할 최소 확률입니다.
/// - 너무 낮으면 비게임 질문이 통과할 수 있어, 제품 컨셉에 맞춰 보수적으로 둡니다.
///
/// treatMissingConfidenceAsHigh
/// - 일부 모델은 확률을 제공하지 않을 수 있습니다(typed 모델 등).
/// - 그 경우 label이 game이면 통과, 아니면 차단하는 정책으로 해석합니다.
struct MessageGateConfig: Equatable {
    var confidenceThreshold: Double = 0.70
    var treatMissingConfidenceAsHigh: Bool = true
}

// MARK: - Gate

/// 입력 텍스트를 평가해 서버 호출 여부를 결정합니다.
///
/// 평가 순서(핵심)
/// 1) 빈 문자열 차단
/// 2) 프롬프트 인젝션 패턴 차단
/// 3) 키/토큰/비밀번호 요청 차단
/// 4) 욕설 차단
/// 5) 게임 키워드 휴리스틱으로 빠른 허용
/// 6) 분류기(CoreML 등) 결과로 최종 결정
///
/// 이렇게 설계한 이유
/// - 앞 단계는 비용이 거의 없고 즉시 판단 가능합니다.
/// - 분류기는 상대적으로 무겁고 실패 가능성이 있어 마지막 단계로 둡니다.
/// - “게임 전용” 정책은 애매할 때 통과보다 차단이 안전합니다.
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

    /// 입력을 평가해 allow/block를 반환합니다.
    ///
    /// 분류기 결과 처리
    /// - label은 ChatModels.GameDomainLabel로 변환해 앱 내부 기준으로 통일합니다.
    /// - confidence가 음수인 경우는 “확률 제공 없음”으로 간주하고, config 정책에 따라 처리합니다.
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

    /// 프롬프트 인젝션 시도를 간단 패턴으로 감지합니다.
    ///
    /// 목적
    /// - 시스템 규칙 무력화/프롬프트 노출 같은 요청을 서버에 전달하지 않기 위함입니다.
    /// - 완벽한 탐지는 어렵지만, 명확한 신호는 선제 차단합니다.
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

    /// 민감정보 요청을 감지합니다.
    ///
    /// 차단 이유
    /// - API 키/토큰/비밀번호 등은 앱이 절대 제공하면 안 되는 정보입니다.
    /// - 질문이 게임 관련이어도 “비밀 정보 요청” 성격이면 우선적으로 차단합니다.
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

    /// 욕설/비속어를 감지합니다.
    ///
    /// 목적
    /// - UX 품질 유지 및 정책 위반 입력을 서버로 보내지 않기 위함입니다.
    /// - 엄격한 필터가 목적이 아니라, 명확한 표현만 최소한으로 차단합니다.
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

    /// 게임 관련 키워드가 뚜렷한 경우 빠르게 통과시키는 휴리스틱입니다.
    ///
    /// 사용하는 이유
    /// - 분류기 호출을 줄여 성능을 확보합니다.
    /// - 명확한 게임 용어는 오탐 위험이 낮아 선통과가 합리적입니다.
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

    /// 정규식 패턴 배열 중 하나라도 매칭되면 true입니다.
    ///
    /// containsSecretRequest에서 공통 로직으로 재사용합니다.
    private func matchesAny(_ text: String, patterns: [String]) -> Bool {
        patterns.contains { pattern in
            text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    /// 게임 외 질문 차단 기본 응답입니다.
    ///
    /// ChatbotPrompts.defaultNonGameReply와 동일한 문구 계열을 유지해,
    /// “게이트 차단”과 “모델 거절”의 사용자 경험이 어색하게 달라지지 않게 합니다.
    static func defaultNonGameReply() -> String {
        "죄송하지만, 현재 요청은 제가 처리할 수 있는 범위를 벗어납니다. 저는 비디오 게임에 대한 정보 제공에 특화되어 있습니다. 비디오 게임 관련 질문이 있으시면 언제든지 도와드리겠습니다!"
    }

    /// 프롬프트 인젝션 차단 시 응답입니다.
    static func defaultInjectionReply() -> String {
        "요청하신 내용은 보안상 처리할 수 없습니다. 게임 관련 질문으로 도와드릴게요."
    }

    /// 민감정보 요청 차단 시 응답입니다.
    static func defaultSecretReply() -> String {
        "보안상 민감한 정보(키/토큰/비밀번호 등)는 제공할 수 없습니다. 게임 관련 질문으로 도와드릴게요."
    }

    /// 욕설 차단 시 응답입니다.
    static func defaultProfanityReply() -> String {
        "표현을 조금만 순화해주시면 게임 관련 질문으로 도와드릴게요."
    }
}
