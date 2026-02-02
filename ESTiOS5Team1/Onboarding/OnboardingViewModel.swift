//
//  OnboardingViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 2/2/26.
//

import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var selectedGenres: Set<GenreFilterType> = []

    private let authService: AuthService

    init(authService: AuthService? = nil) {
        self.authService = authService ?? AuthServiceImpl()
    }

    /// 선호 장르 저장 + 서버 온보딩 완료 반영을 한 번에 처리합니다.
    func completeOnboarding() async throws -> Bool {
        GenrePreferenceStore.save(selectedGenres)
        GenrePreferenceStore.notifyDidChange()

        let response = try await authService.completeOnboarding()
        return response.onboardingCompleted ?? true
    }
}
