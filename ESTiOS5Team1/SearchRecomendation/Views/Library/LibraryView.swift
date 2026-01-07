//
//  LibraryView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//

import SwiftUI

// MARK: - Library View
struct LibraryView: View {
    @EnvironmentObject var favoriteManager: FavoriteManager
    @State private var isSearchActive = false
    @State private var searchText = ""
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // 검색 필터링된 게임 목록
    var filteredGames: [Game] {
        if searchText.isEmpty {
            return favoriteManager.favoriteGames
        } else {
            return favoriteManager.favoriteGames.filter { game in
                game.title.localizedCaseInsensitiveContains(searchText) ||
                game.genre.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 검색바 (조건부 표시)
                    if isSearchActive {
                        LibrarySearchBar(searchText: $searchText, isSearchActive: $isSearchActive)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // 게임 목록
                    ScrollView {
                        if favoriteManager.favoriteGames.isEmpty {
                            EmptyLibraryView()
                        } else if filteredGames.isEmpty {
                            // 검색 결과 없음
                            EmptySearchResultView()
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredGames) { game in
                                    LibraryGameCard(game: game)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 80)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("내 게임")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isSearchActive.toggle()
                            if !isSearchActive {
                                searchText = ""
                            }
                        }
                    }) {
                        Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                            .foregroundColor(.white)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 0.5)
            }
        }
    }
}

// MARK: - Library Search Bar
struct LibrarySearchBar: View {
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("게임 제목 또는 장르로 검색...", text: $searchText)
                .foregroundColor(.white)
                .placeholder(when: searchText.isEmpty) {
                    Text("게임 제목 또는 장르로 검색...")
                        .foregroundColor(.gray)
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

// MARK: - Empty Library View
struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("저장된 게임이 없습니다")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("게임 카드의 하트 아이콘을 눌러\n마음에 드는 게임을 저장하세요")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Empty Search Result View
struct EmptySearchResultView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("검색 결과가 없습니다")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("다른 검색어로 시도해보세요")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Library Game Card
struct LibraryGameCard: View {
    let game: Game
    @EnvironmentObject var favoriteManager: FavoriteManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Game Image
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 240)
                    .cornerRadius(12)
                
                // Rating Badge and Heart Button
                HStack {
                    // Rating Badge
                    if game.rating > 0 {
                        Text(String(format: "%.1f", game.rating))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    // Heart Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            favoriteManager.toggleFavorite(game: game)
                        }
                    }) {
                        Image(systemName: favoriteManager.isFavorite(gameId: game.id) ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                }
                .padding(8)
            }
            
            // Game Info
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(height: 36, alignment: .top)
                
                Text(game.genre)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Preview
struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .environmentObject(FavoriteManager())
    }
}
