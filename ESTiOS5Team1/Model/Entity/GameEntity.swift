//
//  GameEntity.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation

/// 앱 내부에서 사용하는 게임 도메인 모델(Entity)입니다.
///
/// 네트워크 계층의 `IGDBGameListDTO`를
/// 화면 및 비즈니스 로직에서 사용하기 적합한 형태로 변환한 구조체입니다.
///
/// - Important:
/// 이 타입은 **UI나 네트워크에 종속되지 않는 순수 데이터 모델**이며,
/// API 응답의 Optional 값을 정규화하여 앱 전반에서 일관되게 사용됩니다.
struct GameEntity: Identifiable, Hashable {

    /// 게임의 고유 식별자
    ///
    /// IGDB에서 제공하는 게임 ID를 그대로 사용합니다.
    let id: Int

    /// 게임 제목
    ///
    /// IGDB의 `name` 필드를 앱 내부 표현에 맞게 매핑한 값입니다.
    let title: String

    /// 게임 커버 이미지 URL
    ///
    /// IGDB에서 제공하는 `image_id`를 기반으로 생성된 URL이며,
    /// 커버 이미지가 없는 경우 `nil`이 될 수 있습니다.
    let coverURL: URL?

    /// 게임 평점
    ///
    /// IGDB에서 제공하는 평점 값으로,
    /// 평점 정보가 없는 게임의 경우 `nil`입니다.
    /// UI에서는 `"N/A"` 등의 값으로 표현할 수 있습니다.
    let rating: Double?

    /// 게임 장르 목록
    ///
    /// 하나의 게임은 여러 장르를 가질 수 있으며,
    /// 장르 정보가 없는 경우 빈 배열(`[]`)로 정규화됩니다.
    let genre: [String]
}

extension GameEntity {

    /// `IGDBGameListDTO`를 기반으로 `GameEntity`를 생성합니다.
    ///
    /// 네트워크 계층에서 전달받은 DTO를
    /// 앱 내부에서 사용하기 쉬운 형태로 변환합니다.
    ///
    /// - Parameter dto: IGDB API로부터 전달받은 게임 DTO
    init(dto: IGDBGameListDTO) {
        self.id = dto.id
        self.title = dto.name

        if let imageID = dto.cover?.imageID {
            self.coverURL = makeIGDBImageURL(imageID: imageID, id: dto.id)
        } else {
            self.coverURL = nil
        }

        self.rating = dto.rating
        self.genre = dto.genres?.map { $0.name } ?? []
    }
}

