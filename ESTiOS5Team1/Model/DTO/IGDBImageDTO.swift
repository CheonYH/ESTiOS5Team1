//
//  IGDBImageDTO.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation

/// IGDB API에서 제공하는 이미지 정보를 표현하는 DTO입니다.
///
/// 주로 게임의 커버 이미지(`cover`)나 아트워크(`artworks`)에서 사용되며,
/// 실제 이미지 URL을 구성하기 위한 `image_id` 값을 포함합니다.
///
/// - Important:
/// IGDB는 **이미지 전체 URL을 직접 반환하지 않고**,
/// `image_id`를 기반으로 클라이언트에서 URL을 조합하도록 설계되어 있습니다.
/// 따라서 이 DTO는 URL 생성의 재료 역할만 수행합니다.
struct IGDBImageDTO: Codable, Hashable {

    /// IGDB 이미지 서버에서 사용하는 이미지 식별자
    ///
    /// 이 값은 다음과 같은 URL 규칙으로 실제 이미지 주소를 생성할 때 사용됩니다.
    ///
    /// ```
    /// https://images.igdb.com/igdb/image/upload/t_cover_big/{image_id}.jpg
    /// ```
    let imageID: String

    /// JSON 응답의 `image_id` 키를 Swift 프로퍼티 `imageID`로 매핑하기 위한 CodingKeys
    enum CodingKeys: String, CodingKey {
        case imageID = "image_id"
    }
}
