//
//  ReviewSection.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//

import SwiftUI
import UIKit

/// 게임 상세 화면에서 리뷰 영역을 구성하는 섹션 뷰입니다.
///
/// - 역할:
///   - 최신 리뷰 일부(기본 3개) 표시
///   - 내 리뷰 표시 및 수정/삭제
///   - 내 리뷰가 없으면 신규 작성 폼 표시
///   - 키보드 표시 시 에디터가 가려지지 않도록 스크롤/패딩 보정
///
/// - Note:
///   리뷰 변경(작성/수정/삭제) 성공 시 `.reviewDidChange` 알림을 발행하여
///   상위 화면(홈 리스트 등)이 통계/표시를 갱신할 수 있게 합니다.
struct ReviewSection: View {
    /// 리뷰를 표시/작성할 대상 게임 ID입니다.
    let gameId: Int
    /// 리뷰 변경 후(성공 시) 추가로 실행할 콜백입니다.
    ///
    /// 예: 상세 화면 상단의 통계 새로고침 등
    var onReviewChanged: (() async -> Void)?

    /// 리뷰 목록/내 리뷰/통계를 로드하고 CRUD를 수행하는 ViewModel 입니다.
    @StateObject private var viewModel = ReviewViewModel(service: ReviewServiceManager())
    /// 내 리뷰를 수정 모드로 열었는지 여부입니다.
    @State private var isEditingMyReview = false
    /// 토스트 메시지 표시용 매니저입니다.
    @EnvironmentObject private var toastManager: ToastManager
    /// 키보드 높이(표시/숨김)에 따라 바닥 패딩을 조정하기 위한 값입니다.
    @State private var keyboardHeight: CGFloat = 0
    /// '전체 보기' 화면으로 네비게이션할지 여부입니다.
    @State private var showAll: Bool = false

    /// 현재 게임에 대한 내 리뷰(있으면)입니다.
    private var myReview: ReviewResponse? {
        viewModel.myReviews.first(where: { $0.gameId == gameId })
    }

    /// 리뷰 편집(수정) 또는 신규 작성 UI가 활성화되어 있는지 여부입니다.
    private var isEditingOrCreating: Bool {
        isEditingMyReview || myReview == nil
    }

    /// '내 리뷰'를 제외한 최신 리뷰 3개 목록입니다.
    private var latestThree: [ReviewResponse] {
        let filtered = viewModel.reviews.filter { $0.id != myReview?.id }
        return Array(filtered.prefix(3))
    }
    /// 전체 리뷰 목록(네비게이션 '전체 보기'에서 사용)입니다.
    private var reviewList: [ReviewResponse] {
        Array(viewModel.reviews)
    }
    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading) {
                TitleBox(title: "리뷰", showsSeeAll: true, onSeeAllTap: { showAll = true })

                // 리스트(최신 3개)
                ForEach(latestThree) { review in
                    ReviewCellServer(review: review)
                }

                if let myReview {
                    if !isEditingMyReview {
                        TitleBox(title: "내 리뷰", onSeeAllTap: nil)

                        ReviewCellServer(review: myReview)
                    }

                    if isEditingMyReview {
                        Review(
                            initialRating: myReview.rating,
                            initialContent: myReview.content,
                            submitTitle: "수정"
                        ) { rating, content in
                            viewModel.gameId = gameId
                            viewModel.rating = rating
                            viewModel.content = content

                            Task {
                                let event = await viewModel.updateReview(id: myReview.id)
                                toastManager.show(event)
                                if event.status == .success {
                                    isEditingMyReview = false
                                    await viewModel.loadMine()
                                    await onReviewChanged?()
                                    notifyReviewChanged()
                                }
                            }
                        }
                        .id("reviewEditor")

                        HStack {
                            Button("취소") {
                                isEditingMyReview = false
                            }
                            .buttonStyle(.bordered)

                            Spacer()
                        }
                        .padding(.top, 4)
                    } else {
                        HStack {
                            Button("수정") {
                                isEditingMyReview = true
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.textPrimary)

                            Button("삭제") {
                                Task {
                                    let event = await viewModel.deleteReview(id: myReview.id)
                                    toastManager.show(event)
                                    if event.status == .success {
                                        await viewModel.loadMine()
                                        await onReviewChanged?()
                                        notifyReviewChanged()
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.textPrimary)
                        }
                        .padding(.bottom, 8)
                    }
                } else {
                    Review { rating, content in
                        viewModel.gameId = gameId
                        viewModel.rating = rating
                        viewModel.content = content

                        Task {
                            let event = await viewModel.postReview()
                            toastManager.show(event)
                            if event.status == .success {
                                await viewModel.loadMine()
                                await onReviewChanged?()
                                notifyReviewChanged()
                            }
                        }
                    }
                    .id("reviewEditor")
                }

                // 상태 표시
                if viewModel.isLoading {
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }

                if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                }

            }
            .padding(.bottom, isEditingOrCreating ? keyboardHeight : 0)
            .onChange(of: isEditingOrCreating) { _, isEditing in
                guard isEditing else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("reviewEditor", anchor: .bottom)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                guard
                    let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                else { return }
                keyboardHeight = frame.height + 16
                if isEditingOrCreating {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("reviewEditor", anchor: .bottom)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
        }
        // 처음 진입 시 서버에서 불러오기
        .task {
            viewModel.gameId = gameId
            await viewModel.loadReviews(sort: .latest)
            await viewModel.loadStats()
            await viewModel.loadMine()
        }
        .navigationDestination(isPresented: $showAll) {
            ZStack {
                Color.BG.ignoresSafeArea()

                ScrollView {
                    ForEach(reviewList) { review in
                        ReviewCellServer(review: review)
                    }
                }
            }
        }

    }

    /// 리뷰 변경 사항을 앱 전역에 알립니다.
    ///
    /// - Note:
    ///   홈 리스트(트렌딩/릴리즈 등)가 `.reviewDidChange`를 구독해 통계를 갱신합니다.
    private func notifyReviewChanged() {
        NotificationCenter.default.post(
            name: .reviewDidChange,
            object: nil,
            userInfo: ["gameId": gameId]
        )
    }
}

// #Preview {
//    ReviewSection()
// }
