//
//  HomeView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/6/26.
//

import SwiftUI
import Kingfisher

// MARK: - View

/// 메인(홈) 화면의 전체 레이아웃을 구성하는 SwiftUI 뷰입니다.
///
/// 상단 커스텀 네비게이션 헤더와 함께 메인 포스터, 인기 게임, 맞춤 추천, 장르 탐색, 신작 섹션을 배치합니다.
struct HomeView: View {
    /// viewModel에 해당하는 데이터 로더(ViewModel)입니다.
    @ObservedObject var viewModel: GameListSingleQueryViewModel
    /// trendingVM에 해당하는 데이터 로더(ViewModel)입니다.
    @ObservedObject var trendingVM: GameListSingleQueryViewModel
    /// newReleasesVM에 해당하는 데이터 로더(ViewModel)입니다.
    @ObservedObject var newReleasesVM: GameListSingleQueryViewModel
    // [수정] FavoriteManager 연동을 위해 추가
    /// 즐겨찾기(북마크) 상태를 관리하는 매니저입니다.
    @EnvironmentObject var favoriteManager: FavoriteManager
    /// 하단 탭바의 노출 여부 등 탭바 상태를 관리하는 환경 객체입니다.
    @EnvironmentObject var tabBarState: TabBarState
    /// 화면 전환/전체 보기 표시 여부를 제어하는 로컬 상태입니다.
    @State private var showRoot = false
    let onSearchTap: () -> Void
    let onGenreTap: (GameGenreModel) -> Void
    var body: some View {
        VStack {
            CustomNavigationHeader(
                title: "라운지",
                showSearchButton: true,
                isSearchActive: false,
                onSearchTap: { onSearchTap() },
                showRoot: $showRoot
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {

                    if let item = viewModel.items.first {
                        MainPoster(item: item)
                    }

                    TrendingNowGameView(viewModel: trendingVM)

                    TopRatedByGenreCard()

                    BrowseByGenreGridView(onGenreTap: onGenreTap)

                    NewReleasesView(viewModel: newReleasesVM)
                }
            }
            .safeAreaPadding(.bottom, 50)
            .scrollIndicators(.hidden)
            .padding(Spacing.pv10)

            .task {
                if viewModel.items.isEmpty {
                    await viewModel.load()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationDestination(isPresented: $showRoot) {
            RootTabView()
                .onAppear { tabBarState.isHidden = true }
                .onDisappear { tabBarState.isHidden = false }
        }
        .onAppear { tabBarState.isHidden = false }
    }
}
