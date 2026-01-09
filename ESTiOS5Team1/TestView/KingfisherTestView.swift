import SwiftUI
import Kingfisher

/// IGDB API 연동 + UI 표시를 검증하기 위한 임시 테스트 화면입니다.
///
/// - 테스트 목적:
///   - multi-query 요청 동작 검증
///   - DTO → ViewModel → View 출력 흐름 확인
///   - Kingfisher 이미지 로딩 및 캐싱 확인
///
/// - Important:
///   정식 Discover 화면 구성 완료 시 제거되거나 다른 화면으로 대체될 수 있습니다.
struct KingfisherTestView: View {

    /// Discover 섹션 데이터(trending / discover)를 관리하는 ViewModel
    @StateObject private var viewModel = DiscoverViewModel(service: IGDBServiceManager())

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Trending Section
                if !viewModel.trendingItems.isEmpty {
                    Section("Trending") {
                        ForEach(viewModel.trendingItems) { item in
                            GameRow(item: item)
                        }
                    }
                }

                // MARK: - Discover Section
                if !viewModel.discoverItems.isEmpty {
                    Section("Discover") {
                        ForEach(viewModel.discoverItems) { item in
                            GameRow(item: item)
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("로딩 중...")
                }
            }
            .navigationTitle("Discover Test")
            .task {
                await viewModel.load()
            }
        }
    }
}

/// 게임 목록 한 줄을 구성하는 Row View입니다.
///
/// - 표시 요소:
///   - 커버 이미지(Kingfisher 로딩)
///   - 제목(name)
///   - 장르 목록
///   - 평점(rating)
///   - 플랫폼 아이콘 목록
///
/// - Note:
///   실제 디자인은 정식 화면에서 다시 조정될 수 있습니다.
struct GameRow: View {

    let item: GameListItem

    var body: some View {
        HStack(spacing: 12) {

            // MARK: - Cover Image
            KFImage(item.coverURL)
                .placeholder { ProgressView() }
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {

                // MARK: - Title
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                // MARK: - Genre
                if !item.genre.isEmpty {
                    Text(item.genre.joined(separator: " · "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {

                    // MARK: - Rating
                    Text(item.ratingText)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // MARK: - Platform Icons
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
