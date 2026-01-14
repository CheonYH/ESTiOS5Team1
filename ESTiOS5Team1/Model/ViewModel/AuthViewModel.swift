//
//  AuthViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/14/26.
//

import Foundation
import Combine

/// 로그인 화면에서 사용되는 ViewModel입니다.
/// 사용자가 입력한 로그인 정보를 `AuthService`를 통해 서버에 전달하고,
/// 인증 상태를 `AppViewModel`에 반영하는 역할을 합니다.
///
/// 이 ViewModel은 MVVM 아키텍처에서 `Presentation Layer`에 해당합니다.
///
/// - Important:
///     ViewModel은 UI와 직접 연결되지만 `AppViewModel`의 상태 변경을 통해
///     최종적으로 어떤 화면을 표시할지는 상위 계층에서 결정합니다.
///
/// - Note:
///     서버 요청은 비동기로 처리되며, 토큰 저장 및 세션 갱신은 AuthService/AuthLayer에서 담당합니다.
@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Input Fields (UI Bindings)

    /// 사용자가 로그인 화면에서 입력하는 이메일 값입니다.
    @Published var email: String = ""

    /// 사용자가 로그인 화면에서 입력하는 비밀번호 값입니다.
    @Published var password: String = ""

    // MARK: - UI State

    /// 로그인 시 서버 응답 결과나 오류 메시지를 표시할 때 사용됩니다.
    @Published var result: String = ""

    /// 로그인 요청 중 로딩 스피너 표시 등에 사용합니다.
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    /// 실제 로그인 API 요청을 담당하는 서비스 객체입니다.
    ///
    /// 의존성 주입 방식을 사용하여 테스트 및 교체 가능성을 높입니다.
    private let service: AuthService

    // MARK: - Initialization

    /// AuthService를 외부에서 주입하여 초기화합니다.
    ///
    /// - Parameters:
    ///   - service: 로그인 요청 및 토큰 처리를 담당하는 서비스
    init(service: AuthService) {
        self.service = service
    }

    // MARK: - Actions

    /// 로그인 요청을 수행하고 성공 시 AppViewModel에 상태를 전달하여 화면 전환을 유도합니다.
    ///
    /// 로그인 성공 흐름:
    /// 1. 사용자가 이메일/패스워드를 입력
    /// 2. AuthService.login() 호출
    /// 3. 서버에서 access/refresh 발급
    /// 4. TokenStore(Keychain)에 저장
    /// 5. AppViewModel.state = `.signedIn`
    ///
    /// - Important:
    ///     AuthViewModel은 화면 전환을 직접 수행하지 않으며
    ///     전환은 AppViewModel의 상태에 따라 상위(App)에서 처리됩니다.
    func login(appViewModel: AppViewModel) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await service.login(email: email, password: password)
            appViewModel.state = .signedIn
        } catch {
            result = "로그인 실패: \(error)"
        }
    }
}
