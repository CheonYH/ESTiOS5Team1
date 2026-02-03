//
//  NewReleasesView.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/9/26.
//

import SwiftUI

// MARK: - New Releases Section

/// 홈 화면에서 “신규 출시” 게임 목록을 보여주는 섹션 뷰입니다.
///
/// `GameListSingleQueryViewModel`을 주입받아 데이터를 로드하고,
/// `LoadableList`를 통해 로딩/에러/목록 상태를 일관된 UI로 표현합니다.
///
/// - Note:
///     `viewModel.items`가 비어있을 때만 `load()`를 호출해
///     화면 재등장 시 불필요한 중복 호출을 줄입니다.

struct NewReleasesView: View {
    /// 신규 출시 목록 로딩을 담당하는 뷰모델
    @ObservedObject var viewModel: GameListSingleQueryViewModel
    
    /// “전체 보기” 화면 전환 여부
    @State private var showAll: Bool = false
    var body: some View {
        VStack {
            TitleBox(title: "신규 출시", showsSeeAll: true, onSeeAllTap: { showAll = true})
            
            LoadableList(
                isLoading: viewModel.isLoading,
                error: viewModel.error,
                items: viewModel.items,
                limit: 4,
                destination: { item in
                    DetailView(gameId: item.id)
                },
                row: { item in
                    NewReleasesGameCard(item: item)
                }
            )
        }
        .task {
            if viewModel.items.isEmpty {
                await viewModel.load()
            }
        }
        .navigationDestination(isPresented: $showAll) {
            GameListSeeAll(title: "신규 출시", query: IGDBQuery.newReleases)
        }
    }
}
