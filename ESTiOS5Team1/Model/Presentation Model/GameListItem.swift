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

    let id: Int
    let title: String
    let coverURL: URL?
    let ratingText: String
    let genre: [String]
    let platformCategories: [Platform]
    let releaseYearText: String
    let summary: String?

    nonisolated init(entity: GameEntity) {
        self.id = entity.id
        self.title = entity.title
        self.coverURL = entity.coverURL

        self.ratingText = entity.rating
            .map { String(format: "%.1f", $0 / 20.0) } ?? "N/A"

        self.genre = entity.genre

        self.platformCategories = Array(
            Set(entity.platforms.compactMap { Platform(igdbName: $0.name) })
        )

        self.releaseYearText = entity.releaseYear
            .map { "\($0)" } ?? "–"

        self.summary = entity.summary
    }
}
