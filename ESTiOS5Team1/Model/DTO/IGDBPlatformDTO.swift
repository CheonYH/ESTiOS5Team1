import Foundation
import Combine

/// IGDB API에서 전달되는 플랫폼 정보를 표현하는 DTO입니다.
///
/// `games` 조회 시 각 게임에 포함된 플랫폼(`platforms`) 정보나
/// 플랫폼 목록을 직접 조회할 때 사용할 수 있습니다.
///
/// - Important:
/// 이 타입은 **IGDB 원본 스키마 그대로를 반영한 데이터 전송 객체(DTO)**입니다.
/// 앱 내부에서 사용하는 플랫폼 분류, 그룹핑, 아이콘, UI 표현 로직 등은
/// 이 DTO가 아닌 별도의 Domain Layer 또는 ViewModel에서 처리합니다.
///
/// - Note:
/// 플랫폼 이름은 매우 다양하며 일관성이 떨어질 수 있습니다. 예:
/// - "PlayStation 5"
/// - "Xbox Series X|S"
/// - "PC (Microsoft Windows)"
/// - "Super Nintendo Entertainment System"
///
/// IGDB는 일부 플랫폼에 약칭(`abbreviation`)도 제공하며,
/// 존재하지 않는 경우가 있으므로 Optional로 선언되어 있습니다.
struct IGDBPlatformDTO: Codable, Hashable, Identifiable {

    /// IGDB에서 제공하는 플랫폼 고유 식별자
    let id: Int

    /// 플랫폼의 전체 이름
    ///
    /// 예:
    /// "PlayStation 5", "Nintendo Switch", "PC (Microsoft Windows)"
    let name: String

    /// 플랫폼 약칭 (Optional)
    ///
    /// 예:
    /// "PS5", "Switch", "PC"
    ///
    /// 제공되지 않는 플랫폼도 있으므로 Optional 처리됩니다.
    let abbreviation: String?
}
