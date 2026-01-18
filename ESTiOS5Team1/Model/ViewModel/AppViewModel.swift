//
//  AppViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//


import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {

    enum State {
        case launching            // 앱 처음 켜짐
        case signedOut            // 로그인 필요
        case signedIn             // 로그인 완료
    }

    @Published var state: State = .launching
    @Published var prefilledEmail: String? = nil  // 신규 추가

    private let authService: AuthService
    private let toast: ToastManager    // 주입 가능하게 할 수도 있음

    init(authService: AuthService, toast: ToastManager) {
        self.authService = authService
        self.toast = toast
        Task { await restoreSession() }
    }

    /// 이전 세션을 복구합니다 (자동 로그인)
    ///
    /// - Flow:
    ///     1. refreshToken 존재 여부 확인
    ///     2. refresh() 호출하여 accessToken 재발급 시도
    ///     3. 성공 → signedIn
    ///     4. 실패 → signedOut + 안내 메시지 출력
    ///
    /// - Important:
    ///     refreshToken이 만료될 수 있으므로 실패 시 사용자 안내 필요
    func restoreSession() async {
        // refreshToken이 없는 경우 → 로그인 필요
        guard TokenStore.shared.refreshToken() != nil else {
            state = .signedOut
            return
        }

        do {
            try await authService.refresh()
            state = .signedIn

        } catch let authError as AuthError {
            state = .signedOut

            // Token 만료 케이스
            if case .invalidCredentials = authError {
                toast.show(FeedbackEvent(.auth, .info, "세션이 만료되었습니다. 다시 로그인해주세요."))
            } else {
                toast.show(FeedbackEvent(.auth, .warning, "자동 로그인 실패. 다시 로그인해주세요."))
            }

        } catch {
            state = .signedOut
            toast.show(FeedbackEvent(.auth, .error, "알 수 없는 오류가 발생했습니다."))
        }
    }
}

