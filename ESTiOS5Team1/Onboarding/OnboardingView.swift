//
//  OnboardingView.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/30/26.
//
//  앱 최초 실행 시 등장하는 온보딩 화면 (SwiftUI)
//  로그인 이후 표시되며, 마지막 페이지에서 관심 장르를 선택합니다.

import SwiftUI
import FirebaseCrashlytics

// MARK: - Onboarding View

struct OnboardingView: View {
    @State private var currentPage = 0
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool

    private let pages = OnboardingData.pages
    private let totalPages: Int

    init(isOnboardingComplete: Binding<Bool>) {
        self._isOnboardingComplete = isOnboardingComplete
        // 소개 페이지 + 장르 선택 페이지
        self.totalPages = OnboardingData.pages.count + 1
    }

    var body: some View {
        ZStack {
            // 배경색
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // 페이지 컨텐츠
                TabView(selection: $currentPage) {
                    // 소개 페이지들
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }

                    // 장르 선택 페이지 (마지막)
                    GenreSelectionView(
                        selectedGenres: $viewModel.selectedGenres,
                        onComplete: completeOnboarding
                    )
                    .tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // 하단 영역 (페이지 인디케이터 + 버튼)
                bottomControls
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 20) {
            // 페이지 인디케이터
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.purple : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentPage == index ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.top, 20)

            // 다음/건너뛰기 버튼 (마지막 페이지 제외)
            if currentPage < pages.count {
                HStack {
                    // 건너뛰기 버튼
                    Button {
                        withAnimation {
                            currentPage = pages.count
                        }
                    } label: {
                        Text("건너뛰기")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // 다음 버튼
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("다음")
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 30)
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Actions

    private func completeOnboarding() {
        Task {
            do {
                let isCompleted = try await viewModel.completeOnboarding()
                guard isCompleted else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    isOnboardingComplete = true
                }
            } catch {
                print("[Onboarding] complete failed:", error)
                Crashlytics.crashlytics().record(error: error)
                Crashlytics.crashlytics().log("온보딩 완료 처리 실패")
            }
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        if page.isLogoPage {
            // 첫 페이지 (로고) - 별도 레이아웃
            logoPageLayout
        } else {
            // 일반 페이지 레이아웃
            normalPageLayout
        }
    }

    // MARK: - Logo Page Layout (첫 페이지)
    private var logoPageLayout: some View {
        VStack(spacing: 0) {
            Spacer()

            // 로고 이미지
            Image(page.imageName ?? "")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 350, maxHeight: 250)
                .padding(.top, 50)

            // 타이틀 (로고 바로 아래, 간격 조정 가능)
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, -20) // 로고와의 간격 조정

            // 설명
            Text(page.description)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .padding(.top, 16)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Normal Page Layout (일반 페이지)
    private var normalPageLayout: some View {
        VStack(spacing: 24) {
            Spacer()

            // SF Symbol 아이콘
            Image(systemName: page.imageName ?? "questionmark")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.5), radius: 20, x: 0, y: 10)

            // 타이틀
            Text(page.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // 설명
            Text(page.description)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
