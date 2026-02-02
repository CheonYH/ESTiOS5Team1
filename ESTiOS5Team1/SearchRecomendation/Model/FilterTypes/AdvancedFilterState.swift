//
//  AdvancedFilterTypes.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

// MARK: - Sort Type

/// 게임 목록의 정렬 기준을 정의하는 열거형입니다.
///
/// - popularity: 인기순 (기본값, API 응답 순서 유지)
/// - newest: 최신순 (출시 연도 내림차순)
/// - rating: 평점순 (평점 내림차순)
/// - nameAsc: 이름순 (가나다/ABC 오름차순)
enum SortType: String, CaseIterable, Identifiable {
    case popularity = "인기순"
    case newest = "최신순"
    case rating = "평점순"
    case nameAsc = "이름순"

    var id: String { rawValue }

    /// SF Symbols 아이콘 이름
    var icon: String {
        switch self {
        case .popularity: return "flame.fill"
        case .newest: return "clock.fill"
        case .rating: return "star.fill"
        case .nameAsc: return "textformat.abc"
        }
    }
}

// MARK: - Release Period Filter

/// 게임 출시 시기 필터를 정의하는 열거형입니다.
///
/// - all: 전체 기간
/// - month1: 최근 1개월 이내 출시
/// - month6: 최근 6개월 이내 출시
/// - thisYear: 올해 출시작
/// - classic: 5년 이상 된 명작
enum ReleasePeriodFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case month1 = "최근 1개월"
    case month6 = "최근 6개월"
    case thisYear = "올해"
    case classic = "클래식"

    var id: String { rawValue }

    /// SF Symbols 아이콘 이름
    var icon: String {
        switch self {
        case .all: return "calendar"
        case .month1: return "1.circle.fill"
        case .month6: return "6.circle.fill"
        case .thisYear: return "calendar.badge.clock"
        case .classic: return "crown.fill"
        }
    }

    /// 필터 설명 텍스트
    var description: String {
        switch self {
        case .all: return "모든 기간"
        case .month1: return "30일 이내 출시"
        case .month6: return "6개월 이내 출시"
        case .thisYear: return "2026년 출시작"
        case .classic: return "5년 이상 된 명작"
        }
    }

    /// 게임의 출시 연도가 이 필터 조건에 맞는지 확인합니다.
    ///
    /// - Parameter releaseYear: 게임의 출시 연도 문자열
    /// - Returns: 필터 조건 충족 여부
    func matches(releaseYear: String) -> Bool {
        guard releaseYear != "–" else { return self == .all }
        guard let year = Int(releaseYear) else { return self == .all }

        let currentYear = Calendar.current.component(.year, from: Date())

        switch self {
        case .all:
            return true
        case .month1, .month6:
            // 월 단위는 연도만으로 정확히 판단 어려움, 올해로 대체
            return year == currentYear
        case .thisYear:
            return year == currentYear
        case .classic:
            return year <= currentYear - 5
        }
    }
}

// MARK: - Category Filter

/// 게임 카테고리 필터를 정의하는 열거형입니다.
///
/// - all: 전체 카테고리
/// - trending: 현재 인기 상승 중인 게임
/// - newReleases: 최근 출시된 신작
/// - discover: 추천 게임
enum CategoryFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case trending = "Trending Now"
    case newReleases = "New Releases"
    case discover = "Discover"

    var id: String { rawValue }

    /// SF Symbols 아이콘 이름
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .trending: return "chart.line.uptrend.xyaxis"
        case .newReleases: return "sparkle"
        case .discover: return "safari"
        }
    }

    /// 카테고리별 테마 색상
    var color: Color {
        switch self {
        case .all: return .gray
        case .trending: return .orange
        case .newReleases: return .green
        case .discover: return .blue
        }
    }
}

// MARK: - Advanced Filter State

/// 고급 필터 상태를 관리하는 구조체입니다.
struct AdvancedFilterState: Equatable {
    var sortType: SortType = .popularity
    var minimumRating: Double = 0.0
    var releasePeriod: ReleasePeriodFilter = .all
    var category: CategoryFilter = .all

    var hasActiveFilters: Bool {
        sortType != .popularity ||
        minimumRating > 0 ||
        releasePeriod != .all ||
        category != .all
    }

    var activeFilterCount: Int {
        var count = 0
        if sortType != .popularity { count += 1 }
        if minimumRating > 0 { count += 1 }
        if releasePeriod != .all { count += 1 }
        if category != .all { count += 1 }
        return count
    }

    var activeFilterLabels: [String] {
        var labels: [String] = []
        if sortType != .popularity { labels.append(sortType.rawValue) }
        if minimumRating > 0 { labels.append("\(String(format: "%.1f", minimumRating))점 이상") }
        if releasePeriod != .all { labels.append(releasePeriod.rawValue) }
        if category != .all { labels.append(category.rawValue) }
        return labels
    }

    var ratingDisplayText: String {
        if minimumRating == 0 {
            return "전체"
        } else {
            return "\(String(format: "%.1f", minimumRating))점 이상"
        }
    }

    /// 모든 필터를 기본값으로 초기화합니다.
    mutating func reset() {
        sortType = .popularity
        minimumRating = 0.0
        releasePeriod = .all
        category = .all
    }
}
