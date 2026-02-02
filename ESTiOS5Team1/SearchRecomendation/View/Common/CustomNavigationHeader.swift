//
//  CustomNavigationHeader.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/23/26.
//

import SwiftUI

// MARK: - Custom Navigation Header

/// NavigationStack 중첩 문제 해결을 위한 커스텀 네비게이션 헤더입니다.
///
/// - Responsibilities:
///     - 화면 타이틀 표시
///     - 프로필 이미지 버튼 (루트 탭으로 이동)
///     - 검색 버튼 (선택적)
///
/// - Parameters:
///     - title: 헤더 타이틀
///     - showSearchButton: 검색 버튼 표시 여부
///     - isSearchActive: 검색 활성화 상태 (아이콘 변경용)
///     - onSearchTap: 검색 버튼 탭 클로저
///     - showRoot: 루트 탭 표시 상태 바인딩
///
/// - Note:
///     SearchView, LibraryView에서 공통으로 사용됩니다.
struct CustomNavigationHeader: View {
    let title: String
    var showSearchButton: Bool = false
    var isSearchActive: Bool = false
    var onSearchTap: (() -> Void)?
    @Binding var showRoot: Bool

    var body: some View {
        ZStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .leading) {
            Button { showRoot = true } label: {
                Image("ChatImg4")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .font(.title3)
            }
        }
        .overlay(alignment: .trailing) {
            if showSearchButton {
                Button(action: { onSearchTap?() }) {
                    Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                        .foregroundColor(.purple)
                        .font(.title3)
                }
//                .padding(.trailing, 16)
            }
        }
        .padding()
        .background(Color.black)
    }
}

// MARK: - Preview
// #Preview("CustomNavigationHeader") {
//    ZStack {
//        Color.black.ignoresSafeArea()
//
//        VStack {
//            CustomNavigationHeader(
//                title: "게임 탐색",
//                showSearchButton: true,
//                isSearchActive: false,
//                onSearchTap: { print("Search tapped") }
//            )
//
//            CustomNavigationHeader(
//                title: "내 게임",
//                showSearchButton: true,
//                isSearchActive: true,
//                onSearchTap: { print("Search tapped") }
//            )
//
//            Spacer()
//        }
//    }
// }
