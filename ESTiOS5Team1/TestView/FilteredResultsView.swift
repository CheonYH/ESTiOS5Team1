//
//  FilteredResultsView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/20/26.
//

import SwiftUI
import Kingfisher

struct FilteredResultsView: View {

    @StateObject private var viewModel: FilteredResultsViewModel
    private let targetAge: GracAge

    init(age: GracAge) {
        self.targetAge = age
        _viewModel = StateObject(wrappedValue: FilteredResultsViewModel(targetAge: age))
    }

    var body: some View {
        List {
            if viewModel.items.isEmpty && !viewModel.isLoading {
                Text("해당 연령 등급에 맞는 게임이 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.items) { item in
                    row(item)
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("로딩 중…")
            }
        }
        .navigationTitle(titleFor(targetAge))
        .task {
            await viewModel.load()
        }
    }

    private func row(_ item: GameListItem) -> some View {
        HStack {
            KFImage(item.coverURL)
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                Text(item.genre.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(item.ageLabelForTest)   // 테스트용 배지
                    .font(.caption2)
                    .padding(4)
                    .background(.gray.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }

    private func titleFor(_ age: GracAge) -> String {
        switch age {
        case .all: return "전체 이용가"
        case .twelve: return "12세 이상"
        case .fifteen: return "15세 이상"
        case .nineteen: return "청소년 이용불가"
        }
    }
}


