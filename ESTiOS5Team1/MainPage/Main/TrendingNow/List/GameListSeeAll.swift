//
//  GameListSeeAll.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/20/26.
//

import SwiftUI

struct GameListSeeAll: View {
    let title: String
    let query: String

    @StateObject private var viewModel: GameListSingleQueryViewModel
    @EnvironmentObject var tabBarState: TabBarState
    @Environment(\.dismiss) private var dismiss
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
                
                Text("상세 정보")
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
