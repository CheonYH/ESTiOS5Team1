//
//  NicknameValidator.swift
//  ESTiOS5Team1
//
//  Created by Codex on 2/3/26.
//

import Foundation

/// 닉네임 검증 결과 타입입니다.
enum NicknameValidationResult {
    /// 모든 규칙을 통과한 유효한 닉네임입니다.
    case valid
    /// 공백 제외 시 빈 문자열인 경우입니다.
    case empty
    /// 길이 제한(2~12자)을 벗어난 경우입니다.
    case length
    /// 이모지를 포함한 경우입니다.
    case emoji
    /// 동일 문자를 3회 이상 반복한 경우입니다.
    case repeating
    /// 숫자로만 구성된 경우입니다.
    case numericOnly
}

/// 닉네임 검증 규칙을 관리하는 유틸리티입니다.
///
/// - Purpose:
///     닉네임 규칙을 ViewModel과 분리하여 재사용성과 일관성을 확보합니다.
struct NicknameValidator {

    // MARK: - Public API

    /// 닉네임을 검증하고 결과를 반환합니다.
    static func validate(_ nickname: String) -> NicknameValidationResult {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        switch true {
            case trimmed.isEmpty:
                return .empty
            case !(2...12).contains(trimmed.count):
                return .length
            case containsEmoji(trimmed):
                return .emoji
            case hasTooManyRepeatingCharacters(trimmed):
                return .repeating
            case isNumericOnly(trimmed):
                return .numericOnly
            default:
                return .valid
        }
    }

    // MARK: - Private Helpers

    /// 텍스트에 이모지가 포함되어 있는지 검사합니다.
    private static func containsEmoji(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            switch scalar.value {
                case 0x1F600...0x1F64F,
                    0x1F300...0x1F5FF,
                    0x1F680...0x1F6FF,
                    0x2600...0x26FF,
                    0x2700...0x27BF:
                    return true
                default:
                    continue
            }
        }
        return false
    }

    /// 동일 문자 반복 여부 검사 (3회 이상)
    private static func hasTooManyRepeatingCharacters(_ text: String) -> Bool {
        var last: Character?
        var count = 1

        for char in text {
            if char == last {
                count += 1
                if count >= 3 { return true }
            } else {
                count = 1
                last = char
            }
        }
        return false
    }

    /// 숫자로만 구성되어 있는지 검사합니다.
    private static func isNumericOnly(_ text: String) -> Bool {
        !text.isEmpty && text.allSatisfy { $0.isNumber }
    }
}
