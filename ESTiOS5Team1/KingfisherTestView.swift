//
//  KingfisherTestView.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import SwiftUI
import Kingfisher

/// Kingfisher 이미지 로딩과 게임 목록 UI를 테스트하기 위한 화면입니다.
///
/// 실제 앱의 메인 화면이 아닌,
/// - IGDB API 연동
/// - `GameListViewModel` 동작
/// - Kingfisher 이미지 로딩을 빠르게 검증하기 위한 **테스트 목적의 View**입니다.
///
/// - Note:
/// 이후 메인 화면이 구현되면 제거되거나 교체될 수 있습니다.
struct KingfisherTestView: View {

    /// 게임 목록 상태를 관리하는 ViewModel
    @StateObject private var viewModel =
        GameListViewModel(service: IGDBServiceManager())

    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                ProgressView("로딩 중")
            } else if let error = viewModel.error {
                VStack {
                    Text("오류발생")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                List(viewModel.items) { item in
                    GameRow(item: item)
                }
            }
        }
        .onAppear {
            viewModel.loadGames()
        }
    }
}

/// 게임 목록에서 하나의 게임을 표시하는 Row View입니다.
///
/// 커버 이미지, 제목, 장르, 평점을 표시하며,
/// Kingfisher를 사용하여 원격 이미지를 비동기적으로 로드합니다.
struct GameRow: View {

    /// 화면에 표시할 게임 아이템
    let item: GameListItem

    var body: some View {
        HStack(spacing: 12) {
            KFImage(item.coverURL)
                .placeholder {
                    ProgressView()
                }
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                if !item.genre.isEmpty {
                    Text(item.genre.joined(separator: " · "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(item.ratingText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    KingfisherTestView()
}
