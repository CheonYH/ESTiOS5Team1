import Foundation

/// 게임 리스트 UI에서 사용하는 View 전용 모델.
///
/// `GameEntity`를 기반으로 가공된 데이터를 제공하며,
/// 문자열 포맷, 이미지 URL 조립, 장르 및 플랫폼 가공 등을 UI에서 바로 사용할 수 있는 형태로 변환합니다.
///
/// - Important:
/// 이 타입은 화면 표시(View Layer)를 위한 데이터 전용이며,
/// 네트워크 통신, 비즈니스 로직, 캐싱, Domain 처리 등의 책임을 갖지 않습니다.
/// Domain Layer는 `GameEntity`, Networking은 `IGDBGameListDTO`가 담당합니다.
@MainActor
struct GameListItem: Identifiable, Hashable {

    /// 게임 고유 ID입니다.
    let id: Int
    /// 게임 제목입니다.
    let title: String
    /// 커버 이미지 URL입니다. (없을 수 있음)
    let coverURL: URL?
    /// 화면 표시용 평점 문자열입니다.
    let ratingText: String
    /// 장르 목록입니다.
    let genre: [String]
    /// 플랫폼 카테고리 목록입니다.
    let platformCategories: [Platform]
    /// 출시 연도 표시 문자열입니다.
    let releaseYearText: String
    /// 게임 요약 텍스트입니다.
    let summary: String?

    /// `GameEntity`를 UI 전용 모델로 변환합니다.
     init(entity: GameEntity, review: GameReviewEntity) {

        self.id = entity.id
        self.title = entity.title
        self.coverURL = entity.coverURL

        let avg = review.stats?.averageRating ?? 0
        self.ratingText = avg == 0 ? "0/5" : String(format: "%.1f/5", avg)

        self.genre = entity.genre

        self.platformCategories = Array(
            Set(entity.platforms.compactMap { Platform(igdbName: $0.name) })
        )

        self.releaseYearText = entity.releaseYear
            .map { "\($0)" } ?? "–"

        self.summary = entity.summary
    }
}
