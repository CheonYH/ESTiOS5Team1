import Foundation

/// Discover / Trending / Genre 목록 등의 게임 리스트 UI에서 사용되는 View 전용 모델.
///
/// `GameEntity`를 기반으로 가공된 데이터를 제공하며,
/// 문자열 포맷, 이미지 URL 조립, 장르 및 플랫폼 가공 등을 UI에서 바로 사용할 수 있는 형태로 변환합니다.
///
/// - Important:
/// 이 타입은 화면 표시(View Layer)를 위한 데이터 전용이며,
/// 네트워크 통신, 비즈니스 로직, 캐싱, Domain 처리 등의 책임을 갖지 않습니다.
/// Domain Layer는 `GameEntity`, Networking은 `IGDBGameListDTO`가 담당합니다.
struct GameListItem: Identifiable, Hashable {

    /// SwiftUI List/ForEach에서 사용되는 식별자
    let id: Int

    /// 화면 표시용 제목
    let title: String

    /// 커버 이미지 URL
    ///
    /// - Note:
    /// `nil`일 수 있으며, UI에서는 placeholder로 대체하는 것이 일반적입니다.
    let coverURL: URL?

    /// 화면 표시용 평점 문자열
    ///
    /// 예: `"8.5"` / `"N/A"`
    let ratingText: String

    /// 장르 문자열 목록
    ///
    /// 예: `["Action", "RPG"]`
    /// - UI에서는 `"Action · RPG"`로 조합하기 적합한 형태
    let genre: [String]

    /// 플랫폼 Category 매핑 결과
    ///
    /// IGDB 플랫폼 문자열을 내부 `Platform` Enum으로 변환한 결과이며,
    /// 중복은 제거됩니다.
    let platformCategories: [Platform]

    /// GameEntity -> ViewModel 변환 초기화
    ///
    /// - Parameter entity: Domain Layer 모델
    ///
    /// - Important:
    /// 변환 시 presentation 로직이 일부 포함됩니다.
    /// (예: 평점 포맷, 플랫폼 매핑)
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
    }
}
