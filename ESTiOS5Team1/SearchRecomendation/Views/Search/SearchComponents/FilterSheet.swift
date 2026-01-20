//
//  FilterSheet.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

// MARK: - Filter Sheet
struct FilterSheet: View {
    @Binding var filterState: AdvancedFilterState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Category Section
                        FilterSection(title: "카테고리", icon: "square.grid.2x2") {
                            CategoryFilterGrid(selectedCategory: $filterState.category)
                        }

                        Divider()
                            .background(Color.gray.opacity(0.3))

                        // Sort Section
                        FilterSection(title: "정렬", icon: "arrow.up.arrow.down") {
                            SortFilterGrid(selectedSort: $filterState.sortType)
                        }

                        Divider()
                            .background(Color.gray.opacity(0.3))

                        // Rating Section (슬라이더)
                        FilterSection(title: "평점", icon: "star.fill") {
                            RatingSlider(minimumRating: $filterState.minimumRating)
                        }

                        Divider()
                            .background(Color.gray.opacity(0.3))

                        // Release Period Section
                        FilterSection(title: "출시 시기", icon: "calendar") {
                            ReleasePeriodFilterGrid(selectedPeriod: $filterState.releasePeriod)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("초기화") {
                        withAnimation(.spring(response: 0.3)) {
                            filterState.reset()
                        }
                    }
                    .foregroundColor(.red)
                }

                ToolbarItem(placement: .principal) {
                    Text("필터")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
    }
}

// MARK: - Filter Section
struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .font(.subheadline)

                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            content()
        }
    }
}

// MARK: - Category Filter Grid
struct CategoryFilterGrid: View {
    @Binding var selectedCategory: CategoryFilter

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(CategoryFilter.allCases) { category in
                CategoryFilterButton(
                    category: category,
                    isSelected: selectedCategory == category
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
}

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let category: CategoryFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.subheadline)

                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? category.color.opacity(0.3) : Color.white.opacity(0.1)
            )
            .foregroundColor(isSelected ? category.color : .gray)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sort Filter Grid
struct SortFilterGrid: View {
    @Binding var selectedSort: SortType

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(SortType.allCases) { sort in
                FilterOptionButton(
                    title: sort.rawValue,
                    icon: sort.icon,
                    isSelected: selectedSort == sort,
                    color: .purple
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSort = sort
                    }
                }
            }
        }
    }
}

// MARK: - Rating Slider
struct RatingSlider: View {
    @Binding var minimumRating: Double

    var body: some View {
        VStack(spacing: 16) {
            // 현재 평점 표시
            HStack {
                Text("최소 평점")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                if minimumRating == 0 {
                    Text("전체")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", minimumRating))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        Text("이상")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }

            // 슬라이더
            HStack(spacing: 12) {
                Text("0")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 20)

                // 커스텀 슬라이더
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 배경 트랙
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        // 활성화된 트랙
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.6), .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (minimumRating / 5.0), height: 8)

                        // 드래그 가능한 원형 핸들
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 24, height: 24)
                            .shadow(color: .yellow.opacity(0.5), radius: 4)
                            .offset(x: (geometry.size.width - 24) * (minimumRating / 5.0))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let newValue = min(max(0, value.location.x / geometry.size.width * 5.0), 5.0)
                                        // 0.5 단위로 스냅
                                        minimumRating = (newValue * 2).rounded() / 2
                                    }
                            )
                    }
                }
                .frame(height: 24)

                Text("5")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 20)
            }

            // 별점 가이드
            HStack(spacing: 0) {
                ForEach(0..<5) { index in
                    Image(systemName: Double(index) < minimumRating ? "star.fill" : "star")
                        .foregroundColor(Double(index) < minimumRating ? .yellow : .gray.opacity(0.5))
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Release Period Filter Grid
struct ReleasePeriodFilterGrid: View {
    @Binding var selectedPeriod: ReleasePeriodFilter

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach([ReleasePeriodFilter.all, .month1, .month6], id: \.self) { period in
                    FilterOptionButton(
                        title: period.rawValue,
                        icon: period.icon,
                        isSelected: selectedPeriod == period,
                        color: .cyan
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPeriod = period
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                ForEach([ReleasePeriodFilter.thisYear, .classic], id: \.self) { period in
                    FilterOptionButton(
                        title: period.rawValue,
                        icon: period.icon,
                        isSelected: selectedPeriod == period,
                        color: .cyan
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPeriod = period
                        }
                    }
                }

                // Empty space for alignment
                Color.clear
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Generic Filter Option Button
struct FilterOptionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? color.opacity(0.3) : Color.white.opacity(0.1)
            )
            .foregroundColor(isSelected ? color : .gray)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview("FilterSheet") {
    FilterSheet(filterState: .constant(AdvancedFilterState()))
        .preferredColorScheme(.dark)
}
