//
//  TopRatedByGenreConnectionExample.swift
//  ESTiOS5Team1
//
//  Connection example for main screen integration
//

import SwiftUI

struct TopRatedByGenreConnectionExample: View {
    @StateObject private var topRatedVM = TopRatedByGenreViewModel()
    @State private var selectedGenres: Set<GenreFilterType> = []

    // 고정된 장르 목록
    private var sortedGenres: [GenreFilterType] {
        GenreFilterType.allCases
    }

    // 저장된 선호 장르 ID를 GenreFilterType으로 변환
    private func loadStoredGenres() -> Set<GenreFilterType> {
        let storedIds = PreferenceStore.preferredGenreIds
        let singleId = PreferenceStore.preferredGenreId
        let ids = storedIds.isEmpty ? (singleId.map { [$0] } ?? []) : storedIds

        let genres = sortedGenres.filter { genre in
            guard let id = genre.igdbGenreId else { return false }
            return ids.contains(id)
        }
        return Set(genres)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 장르 다중 선택 (기존 GenreFilterType 목록 사용)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sortedGenres) { genre in
                            Button {
                                if selectedGenres.contains(genre) {
                                    selectedGenres.remove(genre)
                                } else {
                                    selectedGenres.insert(genre)
                                }
                            } label: {
                                Text(genre.displayName)
                                    .font(.subheadline)
                                    .fontWeight(selectedGenres.contains(genre) ? .bold : .medium)
                                    .foregroundColor(selectedGenres.contains(genre) ? .white : .gray)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedGenres.contains(genre) ? Color.gray.opacity(0.4) : Color.clear)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }

                // 저장 버튼: 선택 장르를 UserDefaults에 저장 후 갱신
                Button("Save Selected Genres") {
                    let ids = sortedGenres.compactMap { genre in
                        selectedGenres.contains(genre) ? genre.igdbGenreId : nil
                    }
                    PreferenceStore.preferredGenreIds = ids
                    PreferenceStore.preferredGenreId = ids.first
                    Task { await topRatedVM.refresh() }
                }

                // 결과 표시 (테스트용 텍스트 리스트)
                if topRatedVM.isLoading {
                    ProgressView()
                } else if let error = topRatedVM.error {
                    Text("Error: \(error.localizedDescription)")
                } else if topRatedVM.items.isEmpty {
                    Text("No items")
                } else {
                    ForEach(topRatedVM.items) { item in
                        Text(item.title)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // 저장된 선호 장르를 선택 상태에 반영
            selectedGenres = loadStoredGenres()
            // 저장된 선호 장르 기반으로 초기 로드
            Task { await topRatedVM.loadPreferredGenre() }
        }
    }
}

#Preview {
    TopRatedByGenreConnectionExample()
}
