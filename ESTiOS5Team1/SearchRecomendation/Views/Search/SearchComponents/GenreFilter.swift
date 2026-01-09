//
//  GenreFilter.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/9/26.
//

import SwiftUI

// MARK: - Genre Filter
/// 캡슐 스타일의 가로 스크롤 장르 필터
struct GenreFilter: View {
    @Binding var selectedGenre: GenreFilterType

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(GenreFilterType.allCases) { genre in
                    GenreCapsuleButton(
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
    }
}

// MARK: - Genre Capsule Button
struct GenreCapsuleButton: View {
    let genre: GenreFilterType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: genre.iconName)
                    .font(.system(size: 14))

                Text(genre.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? genre.themeColor : Color.white.opacity(0.1))
            .clipShape(Capsule())
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
