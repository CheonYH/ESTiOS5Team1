//
//  GenreFilter.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/9/26.
//
//  [수정] Game → GameListItem 통일

import SwiftUI

// MARK: - Genre Filter
/// 텍스트 스타일의 가로 스크롤 장르 필터 + 하단 구분선 통합
struct GenreFilter: View {
    @Binding var selectedGenre: GenreFilterType
    // [수정] games → items, Game → GameListItem
    var items: [GameListItem] = []

    // 게임 수에 따라 정렬된 장르 목록 ("전체"는 항상 첫 번째)
    private var sortedGenres: [GenreFilterType] {
        let otherGenres = GenreFilterType.allCases.filter { $0 != .all }

        // [수정] 각 장르별 게임 수 계산 - genre가 배열이므로 any로 매칭
        let sorted = otherGenres.sorted { genre1, genre2 in
            let count1 = items.filter { item in
                item.genre.contains { genre1.matches(genre: $0) }
            }.count
            let count2 = items.filter { item in
                item.genre.contains { genre2.matches(genre: $0) }
            }.count
            return count1 > count2
        }

        return [.all] + sorted
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
