//
//  ImageURLGenerator.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation

/// IGDB 이미지 서버에서 지원하는 이미지 사이즈 타입입니다.
///
/// IGDB는 이미지 전체 URL을 직접 제공하지 않고,
/// `image_id`와 사이즈 식별자를 조합하여
/// 클라이언트에서 URL을 생성하도록 설계되어 있습니다.
///
/// - Note:
/// 필요에 따라 `t_cover_small`, `t_logo_med` 등의 사이즈를
/// 추가 정의할 수 있습니다.
enum IGDBImageSize: String {

    /// 게임 커버 이미지 (대형)
    ///
    /// 목록 화면, 상세 화면 등에서 가장 일반적으로 사용되는 사이즈입니다.
    case coverBig = "t_cover_big"
}

/// IGDB 이미지 서버 URL을 생성하는 헬퍼 함수입니다.
///
/// IGDB API 응답으로 전달받은 `image_id`를 기반으로
/// 실제 이미지 리소스에 접근 가능한 URL을 생성합니다.
///
/// - Parameters:
///   - imageID: IGDB에서 제공하는 이미지 식별자(`image_id`)
///   - size: 요청할 이미지 사이즈 (`IGDBImageSize`)
///
/// - Returns:
///   유효한 이미지 URL 또는 URL 생성 실패 시 `nil`
///
/// - Example:
/// ```swift
/// let url = makeIGDBImageURL(imageID: "co4jni")
/// // https://images.igdb.com/igdb/image/upload/t_cover_big/co4jni.jpg
/// ```
///
nonisolated func makeIGDBImageURL(
    imageID: String,
    size: IGDBImageSize = .coverBig
) -> URL? {
    URL(
        string: "https://images.igdb.com/igdb/image/upload/\(size.rawValue)/\(imageID).jpg"
    )
}
