import Combine
import Foundation

/// 인증 관련 에러 타입입니다.
///
/// - invalidCredentials: 이메일/비밀번호 불일치
/// - conflict(String): 중복된 이메일/닉네임 등 충돌 메시지 포함
/// - validation(String): 클라이언트/서버 검증 실패 메시지 포함
/// - server: 서버 내부 오류
/// - network: 네트워크 연결 문제
enum AuthError: Error {
    case invalidCredentials
    case conflict(String) // email or nickname
    case validation(String)
    case server
    case network
}


/// 로그인 화면의 상태 및 로직을 관리하는 ViewModel 입니다.
///
/// - Responsibilities:
///     - 이메일/비밀번호 입력 상태 관리
///     - 로컬 입력 검증
///     - AuthService를 통한 로그인 요청
///     - AppViewModel 상태 전환
///     - FeedbackEvent 반환으로 UI Toast 연결
///
/// - Important:
///     ViewModel은 UI를 직접 변경하지 않고,
///     상태(AppViewModel)와 이벤트(FeedbackEvent)를 통해 화면을 제어합니다.
@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Input

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let service: AuthService

    /// 인증 서비스 의존성을 주입받습니다.
    /// - Parameter service: 로그인/로그아웃 등 인증 API를 담당하는 서비스
    init(service: AuthService) {
        self.service = service
    }

    // MARK: - API

    @discardableResult
    func login(appViewModel: AppViewModel) async -> FeedbackEvent {

        // 1) Local Validation: 입력 단계에서 즉시 검증
        //    유효하지 않은 경우 FeedbackEvent로 즉시 반환하여 UI에 안내
        guard !email.isEmpty else {
            return FeedbackEvent(.auth, .warning, "이메일을 입력해주세요.")
        }

        guard !password.isEmpty else {
            return FeedbackEvent(.auth, .warning, "비밀번호를 입력해주세요.")
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await service.login(email: email, password: password)
            appViewModel.state = .signedIn

            return FeedbackEvent(.auth, .success, "로그인 성공")

        } catch let authError as AuthError {
            switch authError {
            case .invalidCredentials:
                return FeedbackEvent(.auth, .error, "이메일 또는 비밀번호가 올바르지 않습니다.")
            case .conflict(let field):
                return FeedbackEvent(.auth, .error, "\(field)이 이미 사용 중입니다.")
            case .validation(let message):
                return FeedbackEvent(.auth, .warning, message)
            case .network:
                return FeedbackEvent(.auth, .warning, "네트워크 연결을 확인해주세요.")
            case .server:
                return FeedbackEvent(.auth, .error, "서버 오류가 발생했습니다.")
            }

        } catch {
            return FeedbackEvent(.auth, .error, "알 수 없는 오류가 발생했습니다.")
        }
    }

    /// 로그아웃 처리
    ///
    /// - Effects:
    ///     - 토큰 초기화
    ///     - App 상태를 `.signedOut`로 변경
    ///     - 안내용 FeedbackEvent 반환
    ///
    /// - Example:
    ///     ```swift
    ///     let event = viewModel.logout(appViewModel: appVM)
    ///     toast.show(event)
    ///     ```
    func logout(appViewModel: AppViewModel) -> FeedbackEvent {
        TokenStore.shared.clear()
        appViewModel.state = .signedOut

        return FeedbackEvent(
            source: .auth,
            status: .info,
            message: "로그아웃 되었습니다"
        )
    }
}

