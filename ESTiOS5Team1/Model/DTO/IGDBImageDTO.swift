import Foundation

/// IGDB API에서 제공하는 이미지 정보를 담는 DTO입니다.
///
/// 게임의 커버 이미지나 아트워크와 같이
/// 이미지가 필요한 경우 함께 전달되는 데이터입니다.
///
/// 실제 이미지 주소가 아니라,
/// 이미지 URL을 만들기 위한 `image_id` 값만 포함합니다.
///
/// - Important:
/// IGDB는 이미지 전체 URL을 직접 제공하지 않습니다.
/// 대신 `image_id`를 내려주며,
/// 앱에서 이 값을 이용해 이미지 URL을 직접 만들어 사용해야 합니다.
struct IGDBImageDTO: Codable, Hashable {

    /// IGDB 이미지 서버에서 사용하는 이미지 식별자
    ///
    /// 이 값은 아래와 같은 규칙으로 이미지 URL을 만들 때 사용됩니다.
    ///
    /// 예:
    /// https://images.igdb.com/igdb/image/upload/t_cover_big/{image_id}.jpg
    let imageID: String

    /// JSON의 `image_id` 키를
    /// Swift 프로퍼티 `imageID`로 매핑하기 위한 설정
    enum CodingKeys: String, CodingKey {
        case imageID = "image_id"
    }
}
