//
//  IGDBQuery.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/7/26.
//

import Foundation

/// IGDB API 요청에 사용되는 APICALYPSE 쿼리를 정의한 타입입니다.
///
/// 각 쿼리는 화면 목적(Discover, Trending, New Releases)에 맞춰
/// 필요한 필드, 정렬 기준, 필터 조건을 포함합니다.
///
/// - Important:
/// 이 쿼리들은 `/v4/games` 엔드포인트에서 사용되며,
/// 문자열 자체가 API 요청의 본문(body)으로 전달됩니다.
///
/// - Note:
/// 공통 필드 구조를 유지하여
/// 동일한 DTO / Entity / ViewModel 파이프라인을 재사용할 수 있도록 설계되었습니다.
enum IGDBQuery {

    /// Discover 화면용 게임 목록 쿼리
    ///
    /// - 특징:
    ///   - 기본적인 게임 탐색용
    ///   - 정렬 조건 없이 IGDB 기본 정렬 사용
    ///   - 커버 이미지, 평점, 장르, 플랫폼 정보 포함
    ///
    /// - 사용 예:
    ///   - 홈 화면
    ///   - Discover 탭
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

    /// Trending Now 화면용 게임 목록 쿼리
    ///
    /// - 특징:
    ///   - IGDB 내부 인기 지표(`popularity`) 기준 내림차순 정렬
    ///   - 현재 화제성이 높은 게임 목록 표시 목적
    ///
    /// - 사용 예:
    ///   - Trending 섹션
    ///   - 실시간 인기 게임 리스트
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

    /// New Releases 화면용 게임 목록 쿼리
    ///
    /// - 특징:
    ///   - 특정 시점 이후 출시된 게임만 필터링
    ///   - 최신 출시일 기준 내림차순 정렬
    ///
    /// - Note:
    ///   `first_release_date`는 UNIX timestamp(초 단위)이며,
    ///   현재 값은 2024-01-01 기준입니다.
    ///
    /// - 사용 예:
    ///   - 신작 게임 목록
    ///   - 출시 예정/최근 출시 섹션
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
}
