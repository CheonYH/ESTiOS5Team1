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
    limit 300;
    """

    /// 현재 인기 있는 게임(Trending) 목록 쿼리
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
    limit 300;
    """

    /// 최근 출시된 게임 목록 쿼리 (6개월)
    static let newReleases: String = {
        let now = Int(Date().timeIntervalSince1970)
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
        limit 300;
        """
    }()

    /// 특정 장르 기반 쿼리
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

    /// 플랫폼 전체 목록 요청
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
        platforms.name,
        websites.category,
        websites.url,
        videos.video_id,
        videos.name,
        involved_companies.developer,
        involved_companies.publisher,
        involved_companies.company.name;
    """

    /// 검색어 기반 게임 검색 쿼리
    static func search(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return """
        search \"\(escaped)\";
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
        """
    }

    /// 검색어 포함 매칭 (대체 경로)
    static func searchFallback(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return """
        where name ~ *\"\(escaped)\"* | alternative_names.name ~ *\"\(escaped)\"*;
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
        """
    }

}
