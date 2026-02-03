//
//  OnboardingModel.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/30/26.
//
//  온보딩 화면에서 사용할 페이지 구성 정보를 담는 모델

import SwiftUI

// MARK: - Onboarding Page

/// 온보딩 페이지의 개별 데이터를 담는 모델입니다.
///
/// - Properties:
///     - imageName: 페이지에 표시할 이미지 이름 (SF Symbol 또는 Asset)
///     - title: 페이지 제목
///     - description: 페이지 설명 문구
///     - isLogoPage: 로고 페이지 여부 (첫 페이지 레이아웃 구분용)
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

/// 온보딩 화면에서 사용할 정적 데이터를 제공하는 열거형입니다.
///
/// - Note:
///     앱 소개 페이지 5개를 포함하며, 마지막 장르 선택 페이지는 별도 View에서 처리합니다.
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
}
