//
//  MessageGate.swift
//  ESTiOS5Team1
//
//  Created by 김대현 on 1/22/26.
//

import Foundation
import OSLog

// MARK: - Public Types

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
    var gameLabel: String = "game"
    var nonGameLabel: String = "non_game"
    var confidenceThreshold: Double = 0.70
    var enableLogging: Bool = true
}

// MARK: - MessageGate

struct MessageGate {

    private let config: MessageGateConfig
    private let classifier: MessageIntentClassifying?

    private let logger = Logger(
        subsystem: "ESTiOS5Team1",
        category: "MessageGate"
    )

    init(
        config: MessageGateConfig = MessageGateConfig(),
        classifier: MessageIntentClassifying? = nil
    ) {
        self.config = config
        self.classifier = classifier
    }

    // MARK: - Main

    func evaluate(_ rawText: String) -> MessageGateDecision {

        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1) Empty
        guard text.isEmpty == false else {
            log("BLOCK(empty) -> nonGame")
            return .blockNonGame(
                reason: .nonGame,
                reply: Self.defaultNonGameReply()
            )
        }

        // 2) Heuristic blocks
        if containsPromptInjection(text) {
            log("BLOCK(heuristic:promptInjection)")
            return .blockNonGame(
                reason: .promptInjection,
                reply: Self.defaultInjectionReply()
            )
        }

        if containsSecretRequest(text) {
            log("BLOCK(heuristic:secretRequest)")
            return .blockNonGame(
                reason: .secretRequest,
                reply: Self.defaultSecretReply()
            )
        }

        if containsProfanity(text) {
            log("BLOCK(heuristic:profanity)")
            return .blockNonGame(
                reason: .profanity,
                reply: Self.defaultProfanityReply()
            )
        }

        // 3) Light heuristic allow (only obvious game tokens)
        if looksGameByHeuristic(text) {
            log("ALLOW(heuristic:gameTokens)")
            return .allowGame
        }

        // 4) ML
        log("DEBUG(classifier=\(classifier == nil ? "nil" : "non-nil"))")

        guard let prediction = classifier?.predictLabel(text: text) else {
            log("BLOCK(fallback:noClassifierOrNoPrediction) -> nonGame")
            return .blockNonGame(
                reason: .nonGame,
                reply: Self.defaultNonGameReply()
            )
        }

        let label = prediction.label
        let confidence = prediction.confidence

        if label == config.gameLabel,
           confidence >= config.confidenceThreshold {

            log("ALLOW(ml:game conf=\(format(confidence)))")
            return .allowGame
        }

        if label == config.nonGameLabel,
           confidence >= config.confidenceThreshold {

            log("BLOCK(ml:non_game conf=\(format(confidence)))")
            return .blockNonGame(
                reason: .nonGame,
                reply: Self.defaultNonGameReply()
            )
        }

        // Low confidence → block
        log("BLOCK(ml:lowConfidence label=\(label) conf=\(format(confidence)))")
        return .blockNonGame(
            reason: .nonGame,
            reply: Self.defaultNonGameReply()
        )
    }

    // MARK: - Logging

    private func log(_ message: String) {
        guard config.enableLogging else { return }
        print("[MessageGate] \(message)")
        logger.info("\(message, privacy: .public)")
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    // MARK: - Heuristics

    private func containsPromptInjection(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let patterns = [
            "ignore previous",
            "system prompt",
            "reveal prompt",
            "jailbreak",
            "이전 지침 무시",
            "시스템 프롬프트"
        ]
        return patterns.contains { lowered.contains($0) }
    }

    private func containsSecretRequest(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let patterns = [
            "api key",
            "token",
            "password",
            "비밀번호",
            "토큰"
        ]
        return patterns.contains { lowered.contains($0) }
    }

    private func containsProfanity(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let patterns = [
            "씨발", "병신", "fuck", "shit"
        ]
        return patterns.contains { lowered.contains($0) }
    }

    private func looksGameByHeuristic(_ text: String) -> Bool {
        let lowered = text.lowercased()

        let tokens = [
            "공략", "성유물", "빌드", "스킬", "무기",
            "boss", "build", "guide", "artifact",
            "攻略", "ビルド"
        ]

        return tokens.contains { lowered.contains($0) }
    }

    // MARK: - Replies

    static func defaultNonGameReply() -> String {
        "죄송하지만, 저는 비디오 게임 관련 질문(공략/추천/설정 등)에만 답변할 수 있어요."
    }

    static func defaultInjectionReply() -> String {
        "해당 요청은 처리할 수 없어요. 게임 관련 질문으로 부탁드릴게요."
    }

    static func defaultSecretReply() -> String {
        "보안상 민감한 정보 요청은 처리할 수 없어요."
    }

    static func defaultProfanityReply() -> String {
        "거친 표현은 제외하고 게임 관련 질문을 해주세요."
    }
}
