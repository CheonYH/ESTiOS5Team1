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
        case launching
        case signedOut
        case signedIn
    }

    @Published var state: State = .launching

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
        Task {
            await self.restoreSession()
        }
    }

    func restoreSession() async {
        // refreshToken이 존재하는 경우 로그인 유지 시도
        if TokenStore.shared.refreshToken() != nil {
            do {
                try await authService.refresh()
                state = .signedIn
                return
            } catch {
                print("자동 로그인 실패: \(error)")
            }
        }

        // 여기에 오면 refreshToken 없거나 실패한 경우
        state = .signedOut
    }
}
