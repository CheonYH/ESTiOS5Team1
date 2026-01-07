//
//  SearchView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
import SwiftUI

// MARK: - Search View
struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedPlatform: PlatformFilterType = .all
    @State private var isSearchActive = false
    @EnvironmentObject var favoriteManager: FavoriteManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 검색바 (조건부 표시)
                    if isSearchActive {
                        SearchBar(searchText: $searchText, isSearchActive: $isSearchActive)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Platform Filter Buttons
                            PlatformFilter(selectedPlatform: $selectedPlatform)
                            
                            // PC 추천 게임
                            GameSection(
                                title: "PC 추천 게임",
                                games: DummyData.pcGames
                            )
                            
                            // Pinned 게임
                            GameSection(
                                title: "Pinned 게임",
                                games: DummyData.pinnedGames,
                                showLargeCard: true
                            )
                            
                            // New Releases 추천
                            NewReleasesSection()
                            
                            // Coming Soon
                            ComingSoonSection()
                            
                            // PlayStation 추천 게임
                            GameSection(
                                title: "PlayStation 추천 게임",
                                games: DummyData.playstationGames
                            )
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("작품검색")
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

// MARK: - Game Section
struct GameSection: View {
    let title: String
    let games: [Game]
    var showLargeCard: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(games) { game in
                        if showLargeCard {
                            LargeGameCard(game: game)
                        } else {
                            GameCard(game: game)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - New Releases Section
struct NewReleasesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("New Releases")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                ForEach(DummyData.newReleases) { game in
                    NewReleaseCard(game: game)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Coming Soon Section
struct ComingSoonSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Coming Soon")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(DummyData.comingSoon) { game in
                        ComingSoonCard(game: game)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .environmentObject(FavoriteManager())
    }
}
