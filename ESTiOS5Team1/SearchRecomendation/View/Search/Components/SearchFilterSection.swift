//
//  SearchFilterSection.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/27/26.
//
//  [신규] SearchView에서 분리된 필터 섹션 컴포넌트

import SwiftUI

// MARK: - Search Filter Section

/// 검색 화면의 필터 섹션 컴포넌트입니다.
struct SearchFilterSection: View {
    @Binding var selectedPlatform: PlatformFilterType
    @Binding var selectedGenre: GenreFilterType
    @Binding var advancedFilterState: AdvancedFilterState
    @Binding var showFilterSheet: Bool
    let allItems: [GameListItem]

    var body: some View {
        VStack(spacing: 0) {
            // Platform Filter (고정)
            PlatformFilter(selectedPlatform: $selectedPlatform)
                .padding(.top, 10)

            // Genre Filter (고정, 하단 구분선 포함)
            GenreFilter(selectedGenre: $selectedGenre, items: allItems)
                .padding(.top, 10)

            // 고급 필터 버튼 바 (필터 버튼 + 선택된 필터 캡슐)
            FilterButtonBar(
                filterState: $advancedFilterState,
                showFilterSheet: $showFilterSheet
            )
        }
    }
}

// MARK: - Preview
struct SearchFilterSection_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                SearchFilterSection(
                    selectedPlatform: .constant(.all),
                    selectedGenre: .constant(.all),
                    advancedFilterState: .constant(AdvancedFilterState()),
                    showFilterSheet: .constant(false),
                    allItems: []
                )
                Spacer()
            }
        }
    }
}
