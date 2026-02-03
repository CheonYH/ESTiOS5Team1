//
//  GenreFilter.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/9/26.
//
//  [수정] Game → GameListItem 통일

import SwiftUI

// MARK: - Genre Filter

/// 장르별 필터를 제공하는 가로 스크롤 컴포넌트입니다.
///
/// - Responsibilities:
///     - 전체 장르 목록을 텍스트 버튼으로 표시
///     - 선택된 장르에 밑줄 강조
///     - 하단 구분선 포함
///
/// - Parameters:
///     - selectedGenre: 현재 선택된 `GenreFilterType` 바인딩
///     - items: 게임 아이템 배열 (장르 카운트 표시용, 선택적)
struct GenreFilter: View {
    @Binding var selectedGenre: GenreFilterType
    // [수정] games → items, Game → GameListItem
    var items: [GameListItem] = []

    // 고정된 장르 목록 ("전체"는 항상 첫 번째)
    private var sortedGenres: [GenreFilterType] {
        GenreFilterType.allCases
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(sortedGenres) { genre in
                        GenreTextButton(
                            genre: genre,
                            isSelected: selectedGenre == genre
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedGenre = genre
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // 하단 구분선 (회색)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal)
        }
    }
}

// MARK: - Genre Text Button

/// 장르 필터용 텍스트 스타일 버튼 컴포넌트입니다.
struct GenreTextButton: View {
    let genre: GenreFilterType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(genre.displayName)
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : .gray)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                // 선택된 장르 아래 흰색 밑줄 (구분선 위에 겹침)
                Rectangle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(height: 2)
                    .offset(y: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview("GenreFilter") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            GenreFilter(selectedGenre: .constant(.all))
            GenreFilter(selectedGenre: .constant(.shooter))
        }
    }
}
