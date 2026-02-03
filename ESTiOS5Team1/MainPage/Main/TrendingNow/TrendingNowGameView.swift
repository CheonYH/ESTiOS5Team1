//
//  TrendingNowGameView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/7/26.
//

import SwiftUI

// MARK: - View

/// 메인 화면의 '인기 게임' 섹션을 구성하는 뷰입니다.
///
/// 가로 스크롤 카드 목록을 로딩 상태/에러 상태와 함께 표시하고, '전체 보기'로 이동할 수 있습니다.
struct TrendingNowGameView: View {

    /// viewModel에 해당하는 데이터 로더(ViewModel)입니다.
    @ObservedObject var viewModel: GameListSingleQueryViewModel

    /// 화면 전환/전체 보기 표시 여부를 제어하는 로컬 상태입니다.
    @State private var showAll = false
    var body: some View {
        VStack(alignment: .leading) {
            TitleBox(title: "인기 게임", showsSeeAll: true, onSeeAllTap: { showAll = true }
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    LoadableList(
                        isLoading: viewModel.isLoading,
                        error: viewModel.error,
                        items: viewModel.items,
                        destination: { item in
                            DetailView(gameId: item.id)
                        },
                        row: { item in
                            TrendingNowGameCard(item: item)
                        }
                    )
                }
            }
            .ignoresSafeArea(edges: .horizontal)

        }
        .task {
            if viewModel.items.isEmpty {
                await viewModel.load()
            }
        }
        .navigationDestination(isPresented: $showAll) {
            GameListSeeAll(title: "인기 게임", query: IGDBQuery.trendingNow)
        }
    }
}
