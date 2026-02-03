//
//  RegisterViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation
import Combine

/// 회원가입 화면의 상태 및 로직을 관리하는 ViewModel 입니다.
///
/// - Responsibilities:
///     - 사용자가 입력한 회원가입 정보(email, password, nickname)를 관리
///     - 로컬 입력 검증 수행
///     - AuthService를 통해 서버에 회원가입 요청
///     - 회원가입 성공 시 로그인 화면으로 유도
///     - FeedbackEvent를 반환하여 Toast UI로 연결
///
/// - Important:
///     ViewModel은 UI를 직접 변경하지 않고,
///     상태(AppViewModel)와 이벤트(FeedbackEvent)를 통해 화면을 제어합니다.
///
@MainActor
final class RegisterViewModel: ObservableObject {

    // MARK: - Input (사용자 입력 필드)

    /// 이메일 입력값입니다.
    @Published var email = ""
    /// 비밀번호 입력값입니다.
    @Published var password = ""
    /// 비밀번호 확인 입력값입니다.
    @Published var confirmPassword = ""
    /// 닉네임 입력값입니다.
    @Published var nickname = ""

    // MARK: - UI State 표시용

    /// 네트워크 요청 중 로딩 스피너 표시 등에 사용됩니다.
    @Published var isLoading = false

    // MARK: - Dependencies

    /// Auth 도메인 API 호출 담당 서비스입니다.
    private let authService: AuthService

    /// 의존성을 주입해 초기화합니다.
    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Computed Validation Properties

    /// 이메일 형식 검증 (단순 RFC 기반)
    var isEmailValid: Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    /// 비밀번호 규칙 검증 (영문 + 숫자 + 특수문자 + 8자 이상)
    var isPasswordValid: Bool {
        let regex = #"^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*]).{8,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: password)
    }

    /// 비밀번호 재입력 확인 검증
    var isConfirmPasswordValid: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    /// 닉네임 규칙 검증 (길이 + 이모지 + 반복문자 체크)
    var isNicknameValid: Bool {
        NicknameValidator.validate(nickname) == .valid
    }

    /// 모든 항목이 유효한지 여부 (가입 버튼 활성화 조건)
    var canSubmit: Bool {
        isEmailValid && isPasswordValid && isConfirmPasswordValid && isNicknameValid
    }

    // MARK: - API Call (회원가입 처리)

    /// 회원가입 요청 → FeedbackEvent 반환 방식
    ///
    /// - Flow:
    ///     1. 로컬 검증
    ///     2. 서버 요청 (AuthService)
    ///     3. 서버 검증 실패 시 AuthError 매핑
    ///     4. FeedbackEvent 반환하여 Toast로 UI 출력
    ///
    /// - UI Behavior:
    ///     성공 → 로그인 화면 이동 + 이메일 자동 채움
    ///     실패 → Toast로 검증 안내 또는 오류 출력
    @discardableResult
    func register(appViewModel: AppViewModel) async -> FeedbackEvent {
        // 1) 로컬 검증: 빠른 피드백 제공
        if let validationError = validateInputs() {
            return validationError
        }

        // 2) 서버 호출 시작
        isLoading = true
        defer { isLoading = false }

        do {
            let start = CFAbsoluteTimeGetCurrent()
            print("[RegisterVM] register START")
            // 2-1) 닉네임 중복 검사
            let isAvailable = try await authService.checkNickname(nickname)
            let afterNickname = CFAbsoluteTimeGetCurrent()
            print("[RegisterVM] nickname check done in \(String(format: "%.3f", afterNickname - start))s")
            if !isAvailable {
                return FeedbackEvent(.auth, .warning, "이미 사용 중인 닉네임입니다.")
            }

            // 2-2) 회원가입 요청
            _ = try await authService.register(
                email: email,
                password: password,
                nickname: nickname
            )
            let afterRegister = CFAbsoluteTimeGetCurrent()
            print("[RegisterVM] register network done in \(String(format: "%.3f", afterRegister - afterNickname))s total \(String(format: "%.3f", afterRegister - start))s")

            appViewModel.prefilledEmail = email
            appViewModel.state = .signedOut
            let afterState = CFAbsoluteTimeGetCurrent()
            print("[RegisterVM] state updated in \(String(format: "%.3f", afterState - afterRegister))s total \(String(format: "%.3f", afterState - start))s")
            return FeedbackEvent(.auth, .success, "회원가입 완료! 로그인해주세요.")

        } catch {
            return handleRegisterError(error)
        }
    }

    // MARK: - Validation Helpers
    // MARK: - Helper Methods (복잡도 분산)
    private func validateInputs() -> FeedbackEvent? {
        guard !email.isEmpty else { return FeedbackEvent(.auth, .warning, "이메일을 입력해주세요.") }
        guard isEmailValid else { return FeedbackEvent(.auth, .warning, "올바른 이메일 형식이 아닙니다.") }
        guard isPasswordValid else { return FeedbackEvent(.auth, .warning, "비밀번호는 영문/숫자/특수문자 포함 8자 이상이어야 합니다.") }
        guard isConfirmPasswordValid else { return FeedbackEvent(.auth, .warning, "비밀번호 확인이 일치하지 않습니다.") }
        if let nicknameError = nicknameValidationError() { return nicknameError }
        return nil
    }

    private func nicknameValidationError() -> FeedbackEvent? {
        switch NicknameValidator.validate(nickname) {
            case .valid:
                return nil
            case .empty:
                return FeedbackEvent(.auth, .warning, "닉네임을 입력해주세요.")
            case .length:
                return FeedbackEvent(.auth, .warning, "닉네임은 2~12자로 입력해주세요.")
            case .emoji:
                return FeedbackEvent(.auth, .warning, "닉네임에는 이모지를 사용할 수 없습니다.")
            case .repeating:
                return FeedbackEvent(.auth, .warning, "동일 문자는 3회 이상 반복할 수 없습니다.")
            case .numericOnly:
                return FeedbackEvent(.auth, .warning, "닉네임은 숫자만 사용할 수 없습니다.")
        }
    }

    /// 에러 처리 로직만 담당 (복잡도 분리)
    private func handleRegisterError(_ error: Error) -> FeedbackEvent {
        guard let authError = error as? AuthError else {
            return FeedbackEvent(.auth, .error, "알 수 없는 오류가 발생했습니다.")
        }

        switch authError {
            case .validation(let message): return FeedbackEvent(.auth, .warning, message)
            case .network: return FeedbackEvent(.auth, .warning, "네트워크 연결을 확인해주세요.")
            case .server: return FeedbackEvent(.auth, .error, "서버 오류가 발생했습니다.")
            case .conflict(let field): return FeedbackEvent(.auth, .warning, "\(field)이 이미 사용 중입니다.")
            default: return FeedbackEvent(.auth, .error, "회원가입 중 오류가 발생했습니다.")
        }
    }
}
