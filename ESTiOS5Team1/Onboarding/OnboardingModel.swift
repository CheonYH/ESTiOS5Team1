//
//  OnboardingModel.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/30/26.
//
//  온보딩 화면에서 사용할 페이지 구성 정보를 담는 모델

import SwiftUI

// MARK: - Onboarding Model

/// 온보딩 페이지 데이터 모델
struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String?
    let title: String
    let description: String
    let isLogoPage: Bool

    init(
        imageName: String? = nil,
        title: String,
        description: String,
        isLogoPage: Bool = false
    ) {
        self.imageName = imageName
        self.title = title
        self.description = description
        self.isLogoPage = isLogoPage
    }
}

// MARK: - Onboarding Data

enum OnboardingData {
    /// 온보딩 페이지 목록
    static let pages: [OnboardingPage] = [
        .init(
            imageName: "mainLogo",
            title: "PlayerLounge",
            description: "당신만의 게임 라이브러리를 만들고\n새로운 게임을 발견하세요",
            isLogoPage: true
        ),
        .init(
            imageName: "magnifyingglass",
            title: "다양한 게임을 탐색하세요",
            description: "수천 개의 게임 중에서 장르별, 플랫폼별로\n원하는 게임을 쉽게 찾아보세요"
        ),
        .init(
            imageName: "heart.fill",
            title: "나만의 라이브러리 구성",
            description: "마음에 드는 게임을 저장하고\n언제든 쉽게 찾아볼 수 있어요"
        ),
        .init(
            imageName: "star.fill",
            title: "게임 리뷰와 평점",
            description: "다른 플레이어들의 리뷰를 확인하고\n나만의 평가를 남겨보세요"
        ),
        .init(
            imageName: "gamecontroller.fill",
            title: "챗봇과의 1대1 대화",
            description: "챗봇을 통해 게임의 정보와\n공략을 함께 연구해보세요!"
        )
    ]

    /// 온보딩 완료 여부 저장 키
    static let hasSeenOnboardingKey = "hasSeenOnboarding"

    /// 선호 장르 저장 키
    static let preferredGenresKey = "preferredGenres"

    /// 온보딩을 보여줄지 여부 결정
    static func shouldShowOnboarding() -> Bool {
        !UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
    }

    /// 온보딩 완료 처리
    static func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: hasSeenOnboardingKey)
    }

    /// 선호 장르 저장
    static func savePreferredGenres(_ genres: Set<GenreFilterType>) {
        let genreStrings = genres.map { $0.rawValue }
        UserDefaults.standard.set(genreStrings, forKey: preferredGenresKey)
    }

    /// 선호 장르 불러오기
    static func loadPreferredGenres() -> Set<GenreFilterType> {
        guard let genreStrings = UserDefaults.standard.stringArray(forKey: preferredGenresKey) else {
            return []
        }
        return Set(genreStrings.compactMap { GenreFilterType(rawValue: $0) })
    }
}
