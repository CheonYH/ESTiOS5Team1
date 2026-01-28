import Combine
import FirebaseCore
import Foundation
import GoogleSignIn
import FirebaseAuth

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

    /// 이메일 입력값입니다.
    @Published var email: String = ""
    /// 비밀번호 입력값입니다.
    @Published var password: String = ""
    /// 로딩 상태입니다.
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    /// 인증 서비스입니다.
    private let service: AuthService

    /// 인증 서비스 의존성을 주입받습니다.
    /// - Parameter service: 로그인/로그아웃 등 인증 API를 담당하는 서비스
    init(service: AuthService) {
        self.service = service
    }

    // MARK: - API

    /// 로그인 요청을 수행하고 결과 이벤트를 반환합니다.
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
            let start = CFAbsoluteTimeGetCurrent()
            print("[AuthVM] login START")
            _ = try await service.login(email: email, password: password)
            let afterNetwork = CFAbsoluteTimeGetCurrent()
            print("[AuthVM] login network done in \(String(format: "%.3f", afterNetwork - start))s")
            appViewModel.state = .signedIn
            let afterState = CFAbsoluteTimeGetCurrent()
            print("[AuthVM] login state updated in \(String(format: "%.3f", afterState - afterNetwork))s total \(String(format: "%.3f", afterState - start))s")

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
    @discardableResult
    func logout(appViewModel: AppViewModel) -> FeedbackEvent {
        signOutFromSocialProviders()
        TokenStore.shared.clear()
        appViewModel.state = .signedOut

        return FeedbackEvent(
            source: .auth,
            status: .info,
            message: "로그아웃 되었습니다"
        )
    }

    private func signOutFromSocialProviders() {
        GIDSignIn.sharedInstance.signOut()
        do {
            try Auth.auth().signOut()
        } catch {
            print("[AuthVM] Firebase signOut failed:", error)
        }
    }

    @discardableResult
    func signInWithGoogle(appViewModel: AppViewModel) async -> FeedbackEvent {

        print("[AuthVM] signInWithGoogle START")

        do {
            // 1) Google SDK로 idToken 획득
            let (idToken, email) = try await googleAuth()
            print("[AuthVM] Google result received")
            print("[AuthVM] idToken prefix =", idToken.prefix(20))
            print("[AuthVM] email =", email ?? "nil")

            // 2) 서버에 소셜 로그인 요청
            print("[AuthVM] calling Vapor socialLogin")
            let result = try await service.socialLogin(
                idToken: idToken,
                provider: "google"
            )

            switch result {
                case .signedIn(let tokens):
                    // 가입 완료 사용자 → 토큰 저장 + signedIn
                    print("[AuthVM] socialLogin -> signedIn")
                    TokenStore.shared.updateTokens(pair: tokens)
                    appViewModel.state = .signedIn
                    print("[AuthVM] STATE -> signedIn")
                    return FeedbackEvent(.auth, .success, "Google 로그인 성공!")

                case let .needsRegister(serverEmail, providerUid):
                    // 추가 닉네임 등록 필요 → 상태 전환
                    print("[AuthVM] socialLogin -> needsRegister")
                    appViewModel.prefilledEmail = serverEmail ?? email
                    appViewModel.socialProviderUid = providerUid
                    appViewModel.state = .socialNeedsRegister
                    print("[AuthVM] STATE -> socialNeedsRegister")
                    return FeedbackEvent(.auth, .info, "닉네임을 등록해주세요.")
            }

        } catch {
            print("[AuthVM] ERROR:", error)
            return FeedbackEvent(.auth, .error, "Google 로그인 실패")
        }
    }

    func googleAuth() async throws -> (idToken: String, email: String?) {
        print("[AuthVM] googleAuth START")

        // Firebase 설정에서 clientID 확보
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("[AuthVM] ERROR: no clientID")
            throw AuthError.server
        }

        // Google 로그인 UI를 띄울 root VC 조회
        guard let rootVC = await findPresentingViewController() else {
            print("[AuthVM] ERROR: no rootVC")
            throw AuthError.server
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Google 로그인 플로우 진행
        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        print("[AuthVM] google sign-in UI DONE")

        guard let idToken = signInResult.user.idToken?.tokenString else {
            print("[AuthVM] ERROR: no idToken")
            throw AuthError.server
        }

        let email = signInResult.user.profile?.email
        print("[AuthVM] email =", email ?? "nil")

        return (idToken, email)
    }

    func findPresentingViewController() async -> UIViewController? {
        await MainActor.run {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return nil
            }

            guard let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                return nil
            }

            return root.presentedViewController ?? root
        }
    }
}
