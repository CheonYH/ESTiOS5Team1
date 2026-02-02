//
//  SearchBar.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//

import SwiftUI

// MARK: - Search Bar

/// 게임 검색을 위한 검색바 컴포넌트입니다.
///
/// - Responsibilities:
///     - 검색어 입력 필드 제공
///     - 검색어 초기화 버튼
///     - Enter 키 입력 시 검색 실행 콜백
///
/// - Parameters:
///     - searchText: 검색어 바인딩
///     - isSearchActive: 검색 활성화 상태 바인딩
///     - placeholder: 플레이스홀더 텍스트 (기본값: "게임 제목, 장르, 태그 검색...")
///     - onSubmit: Enter 키 입력 시 호출되는 클로저
struct SearchBar: View {
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    var placeholder: String = "게임 제목, 장르, 태그 검색..."
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(placeholder, text: $searchText)
                .foregroundColor(.white)
                .placeholder(when: searchText.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(.gray)
                }
                .onSubmit {
                    onSubmit?()
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
