//
//  SearchHeaderSection.swift
//  ESTiOS5Team1
//
//  Created by Claude on 1/27/26.
//
//  [신규] SearchView에서 분리된 헤더 섹션 컴포넌트

import SwiftUI

// MARK: - Search Header Section

/// 검색 화면의 헤더 섹션 컴포넌트입니다.
///
/// - Responsibilities:
///     - 커스텀 네비게이션 헤더 표시 (타이틀: "게임 탐색")
///     - 검색 버튼 토글로 검색바 표시/숨김
///     - 루트 탭 뷰로의 네비게이션
///
/// - Parameters:
///     - isSearchActive: 검색 활성화 상태 바인딩
///     - searchText: 검색어 바인딩
///     - onSearchSubmit: 검색 실행 클로저
struct SearchHeaderSection: View {
    @Binding var isSearchActive: Bool
    @Binding var searchText: String
    var onSearchSubmit: () -> Void
    @State private var showRoot = false
    @EnvironmentObject var tabBarState: TabBarState
    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 헤더
            CustomNavigationHeader(
                title: "게임 탐색",
                showSearchButton: true,
                isSearchActive: isSearchActive,
                onSearchTap: {
                    withAnimation(.spring(response: 0.3)) {
                        isSearchActive.toggle()
                        if !isSearchActive {
                            searchText = ""
                        }
                    }
                },
                showRoot: $showRoot
            )

            // 검색바 (조건부 표시)
            if isSearchActive {
                SearchBar(
                    searchText: $searchText,
                    isSearchActive: $isSearchActive,
                    onSubmit: onSearchSubmit
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationDestination(isPresented: $showRoot) {
            RootTabView()
                .onAppear { tabBarState.isHidden = true }
                .onDisappear { tabBarState.isHidden = false }
        }
    }
}

// MARK: - Preview
struct SearchHeaderSection_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                SearchHeaderSection(
                    isSearchActive: .constant(true),
                    searchText: .constant("테스트"),
                    onSearchSubmit: {}
                )
                Spacer()
            }
        }
    }
}
