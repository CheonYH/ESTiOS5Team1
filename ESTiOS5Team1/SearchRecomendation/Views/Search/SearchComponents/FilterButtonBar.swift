//
//  FilterButtonBar.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

// MARK: - Filter Button Bar
/// 필터 버튼과 선택된 필터 캡슐을 표시하는 바
struct FilterButtonBar: View {
    @Binding var filterState: AdvancedFilterState
    @Binding var showFilterSheet: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 필터 버튼
                    FilterButton(
                        hasActiveFilters: filterState.hasActiveFilters,
                        activeCount: filterState.activeFilterCount
                    ) {
                        showFilterSheet = true
                    }

                    // 선택된 필터 캡슐들
                    if filterState.category != .all {
                        ActiveFilterCapsule(
                            label: filterState.category.rawValue,
                            color: filterState.category.color,
                            icon: filterState.category.icon
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                filterState.category = .all
                            }
                        }
                    }

                    if filterState.sortType != .popularity {
                        ActiveFilterCapsule(
                            label: filterState.sortType.rawValue,
                            color: .purple,
                            icon: filterState.sortType.icon
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                filterState.sortType = .popularity
                            }
                        }
                    }

                    if filterState.minimumRating > 0 {
                        ActiveFilterCapsule(
                            label: filterState.ratingDisplayText,
                            color: .yellow,
                            icon: "star.fill"
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                filterState.minimumRating = 0
                            }
                        }
                    }

                    if filterState.releasePeriod != .all {
                        ActiveFilterCapsule(
                            label: filterState.releasePeriod.rawValue,
                            color: .cyan,
                            icon: filterState.releasePeriod.icon
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                filterState.releasePeriod = .all
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    let hasActiveFilters: Bool
    let activeCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.subheadline)

                Text("필터")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if activeCount > 0 {
                    Text("\(activeCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                hasActiveFilters ? Color.purple.opacity(0.2) : Color.white.opacity(0.1)
            )
            .foregroundColor(hasActiveFilters ? .purple : .white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(hasActiveFilters ? Color.purple : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Active Filter Capsule
struct ActiveFilterCapsule: View {
    let label: String
    let color: Color
    let icon: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(label)
                .font(.caption)
                .fontWeight(.medium)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview("FilterButtonBar - No Filters") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            FilterButtonBar(
                filterState: .constant(AdvancedFilterState()),
                showFilterSheet: .constant(false)
            )
            Spacer()
        }
    }
}

#Preview("FilterButtonBar - With Filters") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            FilterButtonBar(
                filterState: .constant(AdvancedFilterState(
                    sortType: .newest,
                    minimumRating: 4.0,
                    releasePeriod: .all,
                    category: .trending
                )),
                showFilterSheet: .constant(false)
            )
            Spacer()
        }
    }
}
