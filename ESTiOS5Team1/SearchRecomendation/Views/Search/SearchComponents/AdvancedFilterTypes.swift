//
//  AdvancedFilterTypes.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

// MARK: - Sort Type
enum SortType: String, CaseIterable, Identifiable {
    case popularity = "인기순"
    case newest = "최신순"
    case rating = "평점순"
    case nameAsc = "이름순"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .popularity: return "flame.fill"
        case .newest: return "clock.fill"
        case .rating: return "star.fill"
        case .nameAsc: return "textformat.abc"
        }
    }
}

// MARK: - Rating Filter (슬라이더용)

/// 0.0 ~ 5.0 범위의 최소 평점 값
/// 0.0이면 필터 비활성화 (모든 평점 표시)

// MARK: - Release Period Filter
enum ReleasePeriodFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case month1 = "최근 1개월"
    case month6 = "최근 6개월"
    case thisYear = "올해"
    case classic = "클래식"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "calendar"
        case .month1: return "1.circle.fill"
        case .month6: return "6.circle.fill"
        case .thisYear: return "calendar.badge.clock"
        case .classic: return "crown.fill"
        }
    }

    var description: String {
        switch self {
        case .all: return "모든 기간"
        case .month1: return "30일 이내 출시"
        case .month6: return "6개월 이내 출시"
        case .thisYear: return "2026년 출시작"
        case .classic: return "5년 이상 된 명작"
        }
    }

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

// MARK: - Category Filter (Trending, New Releases 등)
enum CategoryFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case trending = "Trending Now"
    case newReleases = "New Releases"
    case discover = "Discover"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .trending: return "chart.line.uptrend.xyaxis"
        case .newReleases: return "sparkle"
        case .discover: return "safari"
        }
    }

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
struct AdvancedFilterState: Equatable {
    var sortType: SortType = .popularity
    /// 최소 평점 (0.0 ~ 5.0), 0.0이면 필터 비활성화
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

    /// 평점 표시 텍스트
    var ratingDisplayText: String {
        if minimumRating == 0 {
            return "전체"
        } else {
            return "\(String(format: "%.1f", minimumRating))점 이상"
        }
    }

    mutating func reset() {
        sortType = .popularity
        minimumRating = 0.0
        releasePeriod = .all
        category = .all
    }
}
