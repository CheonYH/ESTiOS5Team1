//
//  IGDBQuery.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/7/26.
//

import Foundation

/// IGDB 게임 목록 조회에 사용되는 APICALYPSE 쿼리 모음입니다.
///
/// `/v4/games` 엔드포인트에서 사용되며,
/// 화면마다 필요한 조건에 맞는 쿼리를 미리 정의해두었습니다.
///
/// - Note:
/// 새로운 화면이나 조건이 추가되면
/// ViewModel이나 Service를 수정하지 않고
/// 이 파일에 쿼리만 추가하면 됩니다.
enum IGDBQuery {

    /// Discover 화면에서 사용하는 기본 게임 목록 쿼리
    ///
    /// - Note:
    /// 정렬이나 필터 없이 기본 게임 목록을 가져옵니다.
    static let discover = """
    fields
        id,
        name,
        cover.image_id,
        rating,
        genres.name,
        platforms.name,
        platforms.platform_logo.image_id;
    limit 30;
    """

    /// 현재 인기 있는 게임(Trending) 목록 쿼리
    ///
    /// - Note:
    /// IGDB의 popularity 값을 기준으로
    /// 인기 순서대로 게임을 가져옵니다.
    static let trendingNow = """
    fields
        id,
        name,
        cover.image_id,
        rating,
        genres.name,
        platforms.name,
        platforms.platform_logo.image_id;
    sort popularity desc;
    limit 30;
    """

    /// 최근 출시된 게임 목록 쿼리
    ///
    /// - Note:
    /// 2024년 이후 출시된 게임만 조회하며,
    /// 출시일 기준으로 최신순 정렬합니다.
    static let newReleases = """
    fields
        id,
        name,
        cover.image_id,
        rating,
        genres.name,
        platforms.name,
        platforms.platform_logo.image_id;
    where first_release_date > 1704067200;
    sort first_release_date desc;
    limit 30;
    """

    /// 특정 장르에 해당하는 게임 목록 쿼리
    ///
    /// - Parameter genreId:
    ///   IGDB에서 제공하는 장르 ID 값
    ///
    /// - Note:
    /// 장르별 화면이나 섹션을 구성할 때 사용합니다.
    static func genre(_ genreId: Int) -> String {
        """
        fields
            id,
            name,
            cover.image_id,
            rating,
            genres.name,
            platforms.name,
            platforms.platform_logo.image_id;
        where genres = (\(genreId));
        sort popularity desc;
        limit 30;
        """
    }
}
