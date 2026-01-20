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
        summary,
        aggregated_rating,
        release_dates.y,
        genres.name,
        platforms.name,
        platforms.platform_logo.image_id;
    sort popularity desc;
    limit 100;
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
        summary,
        aggregated_rating,
        release_dates.y,
        genres.name,
        platforms.name,
        platforms.platform_logo.image_id;
    sort popularity desc;
    limit 100;
    """

    /// 최근 출시된 게임 목록 쿼리
    ///
    /// - Note:
    /// 현재 시간으로부터 6개월 전까지의 시간동안 출시한 게임들의 목록을 가져옵니다.
    /// 출시일 기준으로 최신순 정렬합니다.
    static let newReleases: String = {
        // 현재 timestamp
        let now = Int(Date().timeIntervalSince1970)
        // 6개월 = 6 * 30일 기준
        let cutoff = now - (60 * 60 * 24 * 30 * 6)

        return """
        fields
            id,
            name,
            cover.image_id,
            summary,
            aggregated_rating,
            release_dates.y,
            genres.name,
            platforms.name,
            platforms.platform_logo.image_id;
        where status = 2 & first_release_date >= \(cutoff);
        sort first_release_date desc;
        limit 100;
        """
    }()

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

    static let allPlatforms = """
    fields id, name, abbreviation;
    limit 500;
    """

    static let detail = """
    fields
    id,
    name,
    cover.image_id,
    summary,
    storyline,
    aggregated_rating,
    release_dates.y,
    genres.name,
    platforms.name;

    """

}
