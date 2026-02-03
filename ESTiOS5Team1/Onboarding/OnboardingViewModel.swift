//
//  OnboardingViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 2/2/26.
//
//  온보딩 화면의 비즈니스 로직을 담당하는 ViewModel

import Foundation
import Combine

// MARK: - Onboarding ViewModel

/// 온보딩 화면의 상태 관리 및 비즈니스 로직을 담당하는 ViewModel입니다.
///
/// - Responsibilities:
///     - 선택된 장르 상태 관리
///     - 선호 장르 로컬 저장 (GenrePreferenceStore)
///     - 서버에 온보딩 완료 상태 전송
///
/// - Important:
///     - `@MainActor`로 선언되어 UI 업데이트가 메인 스레드에서 수행됩니다.
///     - AuthService를 통해 서버와 통신합니다.
@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 사용자가 선택한 장르 목록입니다.
    @Published var selectedGenres: Set<GenreFilterType> = []

    // MARK: - Private Properties

    private let authService: AuthService

    // MARK: - Initialization

    /// OnboardingViewModel을 초기화합니다.
    ///
    /// - Parameter authService: 인증 서비스 (기본값: AuthServiceImpl)
    init(authService: AuthService? = nil) {
        self.authService = authService ?? AuthServiceImpl()
    }

    // MARK: - Public Methods

    /// 선호 장르 저장 + 서버 온보딩 완료 반영을 한 번에 처리합니다.
    ///
    /// - Returns: 온보딩 완료 여부
    /// - Throws: 네트워크 오류 발생 시
    func completeOnboarding() async throws -> Bool {
        GenrePreferenceStore.save(selectedGenres)
        GenrePreferenceStore.notifyDidChange()

        let response = try await authService.completeOnboarding()
        return response.onboardingCompleted ?? true
    }
}
