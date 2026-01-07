import Foundation

/// IGDB API에서 받아오는 플랫폼 정보를 담는 DTO입니다.
///
/// 게임 목록을 조회할 때 함께 전달되는
/// 플랫폼의 기본 정보(id, name)를 그대로 저장합니다.
///
/// - Important:
/// 이 타입은 **IGDB에서 받은 원본 데이터**를 그대로 담기 위한 DTO입니다.
/// 앱에서 사용하는 플랫폼 분류나 아이콘 정보는
/// 이 타입이 아니라 다른 곳에서 처리합니다.
///
/// - Note:
/// IGDB의 플랫폼 이름은 종류가 매우 많고 형태도 제각각이므로,
/// 이 값을 그대로 화면에 표시하기보다는
/// 앱 내부에서 사용하는 플랫폼 타입으로 변환해서 사용하는 것이 좋습니다.
struct IGDBPlatformDTO: Codable, Hashable, Identifiable {

    /// IGDB에서 제공하는 플랫폼 ID
    let id: Int

    /// 플랫폼 이름
    ///
    /// 예:
    /// - "PlayStation 5"
    /// - "Xbox Series X|S"
    /// - "PC (Microsoft Windows)"
    /// - "Nintendo Switch"
    let name: String
}
