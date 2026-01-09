//
//  GenreListTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/8/26.
//

import SwiftUI

/// IGDB 장르 목록 로딩을 테스트하기 위한 임시 화면입니다.
///
/// - 테스트 목적:
///   - IGDB 장르 API 연동 확인
///   - `GenreListViewModel` 상태 변화 확인
///   - ID/Name 기반의 장르 데이터 구조 이해
///
/// - Important:
///   Genre 데이터는 플랫폼처럼 비교적 정적 메타데이터이며,
///   게임 상세/추천/검색/필터 화면에서 재사용될 수 있는 기반 데이터입니다.
///
/// - Note:
///   실제 앱 UI가 아니며,
///   개발 중 검증 및 데이터 관찰을 위한 테스트용 구성입니다.
///   정식 UI가 완성되면 제거되거나 대체될 수 있습니다.
struct GenreListTestView: View {

    /// 장르 목록 상태를 관리하는 ViewModel
    @StateObject private var viewModel =
        GenreListViewModel(service: IGDBServiceManager())

    var body: some View {
        NavigationStack {
            List(viewModel.genres) { genre in
                VStack(alignment: .leading, spacing: 2) {

                    // 장르 이름
                    Text(genre.name)
                        .font(.body)

                    // 장르 ID (추후 필터링/쿼리에서 사용)
                    Text("ID: \(genre.id)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("로딩 중...")
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
