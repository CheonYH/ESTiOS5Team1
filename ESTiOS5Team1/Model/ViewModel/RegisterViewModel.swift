//
//  RegisterViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation
import Combine

/// 회원가입 화면의 상태 및 로직을 관리하는 ViewModel
///
/// - Responsibilities:
///     - 사용자 입력(email / password / nickname)의 상태 관리
///     - 로컬 검증(Validation)
///     - 서버에 회원가입 요청 수행
///     - UI에서 가입 버튼 활성화 여부 판단
///
/// - Design:
///     ViewModel은 View에 종속되지 않으며 AuthService를 통해 서버와 통신함.
///     Entity를 별도 정의하지 않고 ViewModel에서 직접 입력값 검증을 처리하는 방식.
///
/// - Note:
///     실제 서비스에서는 Validation 요구사항에 따라 강화 가능하며,
///     닉네임 중복검사 등은 서버 검증이 추가될 수 있음.
@MainActor
final class RegisterViewModel: ObservableObject {

    // MARK: - Input (사용자 입력)

    /// 가입 이메일 입력
    @Published var email: String = ""

    /// 가입 비밀번호 입력
    @Published var password: String = ""

    /// 가입 비밀번호 확인 입력
    @Published var confirmPassword: String = ""

    /// 가입 닉네임 입력
    @Published var nickname: String = ""

    // MARK: - Output (UI 표시용)

    /// 서버 응답 결과 또는 오류 메시지
    @Published var result: String?

    // MARK: - Dependencies

    /// 서버 통신 담당 AuthService
    private let authService: AuthService

    // MARK: - Initialization

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Local Validation (클라이언트 검증)

    /// 이메일 형식 검증
    ///
    /// - Rule:
    ///     RFC2822의 단순화된 정규식을 사용하여 email@domain 형태를 확인합니다.
    ///
    /// - Important:
    ///     실제 서비스는 국제 이메일 규격이 더 복잡할 수 있으나
    ///     현재 단계에서는 단순화된 정규식을 사용해 검증합니다.
    var isEmailValid: Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    /// 비밀번호 검증
    ///
    /// - Rules:
    ///     - 최소 8자 이상
    ///     - 영문 포함
    ///     - 숫자 포함
    ///     - 특수문자 포함 (!@#$%^&* 등)
    ///
    /// - Important:
    ///     본 규칙은 회원가입 시 비밀번호 생성 조건을 만족하도록 검증합니다.
    var isPasswordValid: Bool {
        // (?=.*[A-Za-z])  → 영문 포함
        // (?=.*\d)        → 숫자 포함
        // (?=.*[!@#$%^&*]) → 특수문자 포함
        // .{8,}           → 최소 길이 8자
        let regex = #"^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*]).{8,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: password)
    }

    /// 비밀번호와 재입력 비밀번호 일치 여부 검증
    var isConfirmPasswordValid: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    /// 닉네임 검증
    ///
    /// - Rules:
    ///     - 공백 제거 후 길이 2 ~ 12자
    ///     - 이모지 포함 불가
    ///     - 과도한 연속문자 포함 불가 (예: ㅋㅋㅋㅋ / aaa / 111 등)
    ///
    /// - Important:
    ///     닉네임 중복 여부는 서버를 통해 검증합니다.
    var isNicknameValid: Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2 &&
               trimmed.count <= 12 &&
               !containsEmoji(trimmed) &&
               !hasTooManyRepeatingCharacters(trimmed)
    }

    /// 모든 항목이 유효한지 여부
    ///
    /// - Usage:
    ///     가입 버튼 활성화 조건으로 활용 가능
    var canSubmit: Bool {
        isEmailValid && isPasswordValid && isConfirmPasswordValid && isNicknameValid
    }

    // MARK: - API Call

    /// 회원가입 요청
    ///
    /// - Operation:
    ///     클라이언트 검증 통과 후 서버에 register 요청 수행합니다.
    ///
    /// - UI Feedback:
    ///     성공/실패 메시지는 `result` Published 속성 값으로 노출됩니다.
    func register() async {
        // 서버 보내기 전에 1차 사전 검증을 진행합니다.
        guard canSubmit else {
            result = "입력된 정보를 다시 확인해주세요."
            return
        }

        do {
            _ = try await authService.register(email: email, password: password, nickname: nickname)
            result = "회원가입 성공"
        } catch {
            result = "회원가입 실패: \(error)"
        }
    }

    // MARK: - Validation Helpers

    /// 텍스트에 이모지가 포함되어 있는지 검사합니다.
    ///
    /// - Reason:
    ///     닉네임에서 이모지는 대부분의 서비스에서 사용을 제한합니다.
    ///
    /// - Note:
    ///     Unicode Scalar 범위 기반 검사이며 확장 가능합니다.
    private func containsEmoji(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // emoticons
                 0x1F300...0x1F5FF, // symbols & pictographs
                 0x1F680...0x1F6FF, // transport & map
                 0x2600...0x26FF,   // miscellaneous symbols
                 0x2700...0x27BF:   // dingbats
                return true
            default: continue
            }
        }
        return false
    }

    /// 동일 문자 반복 여부 검사 (3회 이상)
    ///
    /// - Example:
    ///     "aaa" → true
    ///     "ㅋㅋㅋㅋ" → true
    ///     "111" → true
    ///
    /// - Note:
    ///     게임/커뮤니티 환경에서 품질 낮은 닉네임 방지하기 위해 사용합니다.
    private func hasTooManyRepeatingCharacters(_ text: String) -> Bool {
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
}


