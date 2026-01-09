//
//  KingfisherTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import SwiftUI
import Kingfisher

/// 게임 목록 UI와 이미지 로딩을 테스트하기 위한 임시 화면입니다.
///
/// 이 View는 실제 메인 화면이 아니라,
/// 다음 기능들을 빠르게 확인하기 위한 테스트 용도로 사용됩니다.
/// - IGDB API 연동
/// - `GameListViewModel` 동작 여부
/// - Kingfisher를 이용한 이미지 로딩
///
/// - Important:
/// 앱의 정식 화면이 아니며,
/// 메인 UI 구현이 완료되면 제거되거나 교체될 수 있습니다.
struct KingfisherTestView: View {

    /// 게임 목록 상태를 관리하는 ViewModel
    @StateObject private var viewModel =
        GameListViewModel(
            service: IGDBServiceManager(),
            query: IGDBQuery.discover
        )

    var body: some View {
        NavigationStack {
            List(viewModel.items) { item in
                GameRow(item: item)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("로딩 중")
                }
            }
            .navigationTitle("Discover")
            .onAppear {
                viewModel.loadGames()
            }
        }
    }
}

/// 게임 목록에서 하나의 게임을 표시하는 Row View입니다.
///
/// 게임 커버 이미지, 제목, 장르, 평점,
/// 그리고 지원 플랫폼 아이콘을 함께 표시합니다.
struct GameRow: View {

    /// 화면에 표시할 게임 정보
    let item: GameListItem

    var body: some View {
        HStack(spacing: 12) {

            // 게임 커버 이미지
            KFImage(item.coverURL)
                .placeholder { ProgressView() }
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {

                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                // 장르 표시
                if !item.genre.isEmpty {
                    Text(item.genre.joined(separator: " · "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {

                    // 평점 표시
                    Text(item.ratingText)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // 지원 플랫폼 아이콘
                    HStack(spacing: 4) {
                        ForEach(item.platformCategories, id: \.self) { platform in
                            Image(systemName: platform.iconName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    KingfisherTestView()
}
