//
//  GameListSeeAll.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/20/26.
//

import SwiftUI

// MARK: - View

/// 섹션의 '전체 보기' 목록 화면을 구성하는 뷰입니다.
///
/// 전달받은 IGDB 쿼리로 게임 목록을 로드하고, 세로 리스트 형태로 상세 화면 네비게이션을 제공합니다.
struct GameListSeeAll: View {
    let title: String
    let query: String

    /// viewModel에 해당하는 데이터 로더(ViewModel)입니다.
    @StateObject private var viewModel: GameListSingleQueryViewModel
    /// 하단 탭바의 노출 여부 등 탭바 상태를 관리하는 환경 객체입니다.
    @EnvironmentObject var tabBarState: TabBarState
    /// 현재 화면을 닫기 위한 dismiss 액션입니다.
    @Environment(\.dismiss) private var dismiss
    /// 뷰/타입을 초기화합니다.
    ///
    /// - Parameters:
    ///   - title:
    ///   - query:
    ///
    /// - Note:
    ///   필요에 따라 호출부에서 상태 업데이트/네비게이션을 처리합니다.
    init (title: String, query: String) {
        self.title = title
        self.query = query
        _viewModel = StateObject(
            wrappedValue: GameListSingleQueryViewModel(
                service: IGDBServiceManager(),
                query: query
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text("게임 목록")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Spacer()

                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5)
            ScrollView {
                LazyVStack(spacing: 12) {
                    LoadableList(
                        isLoading: viewModel.isLoading,
                        error: viewModel.error,
                        items: viewModel.items,
                        destination: { item in
                            DetailView(gameId: item.id)
                        },
                        row: { item in
                            GameListRow(item: item)
                        }
                    )
                }
                .padding(.horizontal, Spacing.pv10)
                .padding(.top, 12)
            }
        }
        .background(Color.BG.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear { tabBarState.isHidden = true }
        .onDisappear { tabBarState.isHidden = false }
        .task {
            await viewModel.load()
        }
    }
}
