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
    var gameLabel: String = "game"
    var nonGameLabel: String = "non_game"
    var confidenceThreshold: Double = 0.70
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
            return .blockNonGame(
                reason: .nonGame,
                reply: Self.defaultNonGameReply()
            )
        }

        if containsPromptInjection(text) {
            return .blockNonGame(
                reason: .promptInjection,
                reply: Self.defaultInjectionReply()
            )
        }

        if containsSecretRequest(text) {
            return .blockNonGame(
                reason: .secretRequest,
                reply: Self.defaultSecretReply()
            )
        }

        if containsProfanity(text) {
            return .blockNonGame(
                reason: .profanity,
                reply: Self.defaultProfanityReply()
            )
        }

        if looksGameByHeuristic(text) {
            return .allowGame
        }

        if let prediction = classifier?.predictLabel(text: text) {
            if prediction.label == config.gameLabel, prediction.confidence >= config.confidenceThreshold {
                return .allowGame
            }

            if prediction.label == config.nonGameLabel, prediction.confidence >= config.confidenceThreshold {
                return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
            }
        }

        return .blockNonGame(reason: .nonGame, reply: Self.defaultNonGameReply())
    }

    // MARK: - Heuristics

    private func containsPromptInjection(_ text: String) -> Bool {
        let lowered = text.lowercased()

        let patterns: [String] = [
            "ignore previous",
            "disregard previous",
            "system prompt",
            "developer instructions",
            "hidden instructions",
            "reveal prompt",
            "print prompt",
            "show prompt",
            "internal setting",
            "secret",
            "prompt injection",
            "jailbreak",
            "override",
            "bypass",

            "이전 지침 무시",
            "지침 무시",
            "규칙 무시",
            "시스템 프롬프트",
            "개발자 지침",
            "내부 지침",
            "숨겨진 지침",
            "프롬프트 출력",
            "설정 보여",
            "내부 설정",

            "前の指示を無視",
            "システムプロンプト",
            "開発者の指示",
            "内部の指示",
            "隠された指示",
            "プロンプトを表示"
        ]

        return patterns.contains { lowered.contains($0) }
    }

    private func containsSecretRequest(_ text: String) -> Bool {
        let lowered = text.lowercased()

        let patterns: [String] = [
            "api key",
            "apikey",
            "token",
            "secret key",
            "client key",
            "password",

            "키를 알려",
            "api키",
            "api 키",
            "토큰",
            "비밀번호",
            "클라이언트 키",

            "apiキー",
            "トークン",
            "パスワード",
            "秘密鍵"
        ]

        return patterns.contains { lowered.contains($0) }
    }

    private func containsProfanity(_ text: String) -> Bool {
        let lowered = text.lowercased()

        let tokens: [String] = [
            "씨발", "ㅅㅂ", "시발", "좆", "병신", "미친놈", "존나",

            "fuck", "fucking", "shit", "bitch", "asshole",

            "死ね", "くそ", "クソ"
        ]

        return tokens.contains { lowered.contains($0) }
    }

    private func looksGameByHeuristic(_ text: String) -> Bool {
        let lowered = text.lowercased()

        let gameTokens: [String] = [
            // KR (초단문 포함)
            "공략", "육성", "빌드", "세팅", "스킬트리", "스킬 트리", "스킬", "성유물", "무기",
            "파티", "조합", "보스", "패턴", "딜사이클", "딜 사이클", "스탯", "레벨업", "강화",
            "드랍", "파밍", "던전", "레이드", "퀘스트", "가챠", "천장", "확률",
            "패치노트", "패치 노트", "너프", "버프", "dps",

            // Genres (단독 입력 대비)
            "rpg", "롤플레잉", "role-playing", "action", "roguelike", "roguelite",
            "soulslike", "souls-like", "jrpg", "mmo", "fps", "tps",

            // EN
            "guide", "walkthrough", "build", "setup", "skill tree", "artifact", "weapon",
            "party", "boss", "pattern", "rotation", "stat", "level up", "upgrade",
            "drop", "farm", "dungeon", "raid", "quest", "gacha", "pity",
            "patch notes", "nerf", "buff",

            // JA
            "攻略", "育成", "ビルド", "装備", "スキルツリー", "聖遺物", "武器",
            "パーティ", "ボス", "レイド", "ダンジョン", "ドロップ", "周回",
            "パッチ", "ナーフ", "バフ"
        ]

        if gameTokens.contains(where: { lowered.contains($0) }) {
            return true
        }

        // “푸리나 성유물”, “마비카 스킬트리” 같은 형태(고유명사 1~2단어 + 게임토큰) 보강
        let compactPatterns: [String] = [
            #"(?i)\b[\p{L}\p{N}\-]{2,}\s*(성유물|스킬트리|스킬\s*트리|빌드|공략|육성)\b"#,
            #"(?i)\b(artifact|skill\s*tree|build|guide)\b"#
        ]

        return compactPatterns.contains { pattern in
            lowered.range(of: pattern, options: .regularExpression) != nil
        }
    }

    // MARK: - Replies

    static func defaultNonGameReply() -> String {
        "죄송하지만, 저는 **비디오 게임 관련 질문(공략/추천/설정 등)**에만 답변할 수 있어요. 게임 질문으로 다시 부탁드릴게요!"
    }

    static func defaultInjectionReply() -> String {
        "요청하신 내용은 안전/보안상 응답할 수 없어요. 대신 **게임 관련 질문**이라면 바로 도와드릴게요!"
    }

    static func defaultSecretReply() -> String {
        "보안상 **키/토큰/비밀번호 등 민감정보**는 제공하거나 처리할 수 없어요. 게임 관련 질문으로 부탁드릴게요!"
    }

    static func defaultProfanityReply() -> String {
        "거친 표현은 제외하고 다시 말해주시면, **게임 관련 내용**은 최대한 도와드릴게요."
    }
}
