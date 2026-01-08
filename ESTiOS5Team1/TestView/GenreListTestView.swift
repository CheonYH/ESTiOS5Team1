//
//  GenreListTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/8/26.
//

import SwiftUI

/// 장르 목록 로딩을 테스트하기 위한 임시 화면입니다.
///
/// - 테스트 목적:
///   - IGDB 장르 API 연동 확인
///   - `GenreListViewModel` 동작 여부 확인
///
/// - Note:
///   실제 앱 UI가 아니며,
///   개발 중 테스트 용도로만 사용됩니다.
struct GenreListTestView: View {

    /// 장르 목록 상태를 관리하는 ViewModel
    @StateObject private var viewModel =
        GenreListViewModel(service: IGDBServiceManager())

    var body: some View {
        NavigationStack {
            List(viewModel.genres) { genre in
                Text(genre.name)
                    .font(.body)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("로딩 중")
                }
            }
            .navigationTitle("Genres")
            .task {
                await viewModel.loadGenres()
            }
        }
    }
}

#Preview {
    GenreListTestView()
}
