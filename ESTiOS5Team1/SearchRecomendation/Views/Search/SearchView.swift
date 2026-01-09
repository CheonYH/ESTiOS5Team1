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
    
    @StateObject private var viewModel: SearchViewModel
    @EnvironmentObject var favoriteManager: FavoriteManager
    
    init(favoriteManager: FavoriteManager) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(favoriteManager: favoriteManager))
    }
    
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
                                .padding(.top, 8)
                            
                            // 로딩 또는 에러 상태
                            if viewModel.isLoading && viewModel.discoverGames.isEmpty {
                                LoadingView()
                            } else if let error = viewModel.error, viewModel.discoverGames.isEmpty {
                                ErrorView(error: error) {
                                    viewModel.loadAllGames()
                                }
                            } else {
                                // 플랫폼별 컨텐츠 표시
                                if selectedPlatform == .all {
                                    // 전체: 모든 플랫폼별 한 줄씩
                                    AllPlatformsView(
                                        pcGames: filteredGames(viewModel.discoverGames, platform: .pc),
                                        playstationGames: filteredGames(viewModel.trendingGames, platform: .playstation),
                                        xboxGames: filteredGames(viewModel.newReleaseGames, platform: .xbox),
                                        nintendoGames: filteredGames(viewModel.discoverGames, platform: .nintendo)
                                    )
                                } else {
                                    // 특정 플랫폼: 세로 스크롤 카드
                                    PlatformDetailView(
                                        platform: selectedPlatform,
                                        games: getGamesForPlatform(selectedPlatform)
                                    )
                                }
                            }
                        }
                        .padding(.bottom, 80)
                    }
                    .refreshable {
                        viewModel.loadAllGames()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 중앙: 추천 검색 타이틀
                ToolbarItem(placement: .principal) {
                    Text("추천 검색")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // 오른쪽: 검색 버튼
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
                            .font(.title3)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 0.5)
            }
        }
        .onAppear {
            if viewModel.discoverGames.isEmpty {
                viewModel.loadAllGames()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 플랫폼 필터링 적용
    private func filteredGames(_ games: [Game], platform: PlatformFilterType) -> [Game] {
        guard platform != .all else { return games }
        
        return games.filter { game in
            game.platforms.contains { gamePlatform in
                switch platform {
                    case .all:
                        return true
                    case .pc:
                        return gamePlatform == .pc
                    case .playstation:
                        return gamePlatform == .playstation
                    case .xbox:
                        return gamePlatform == .xbox
                    case .nintendo:
                        return gamePlatform == .nintendo
                }
            }
        }
    }
    
    /// 선택된 플랫폼의 게임 가져오기
    private func getGamesForPlatform(_ platform: PlatformFilterType) -> [Game] {
        let allGames = viewModel.discoverGames + viewModel.trendingGames + viewModel.newReleaseGames
        return filteredGames(allGames, platform: platform)
    }
}

// MARK: - All Platforms View (전체 선택 시)
struct AllPlatformsView: View {
    let pcGames: [Game]
    let playstationGames: [Game]
    let xboxGames: [Game]
    let nintendoGames: [Game]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // PC 추천 게임
            if !pcGames.isEmpty {
                GameSection(
                    title: "PC 추천 게임",
                    games: Array(pcGames.prefix(10)),
                    icon: "desktopcomputer"
                )
            }
            
            // PlayStation 추천 게임
            if !playstationGames.isEmpty {
                GameSection(
                    title: "PlayStation 추천 게임",
                    games: Array(playstationGames.prefix(10)),
                    icon: "playstation.logo"
                )
            }
            
            // Xbox 추천 게임
            if !xboxGames.isEmpty {
                GameSection(
                    title: "Xbox 추천 게임",
                    games: Array(xboxGames.prefix(10)),
                    icon: "xbox.logo"
                )
            }
            
            // Nintendo 추천 게임
            if !nintendoGames.isEmpty {
                GameSection(
                    title: "Nintendo 추천 게임",
                    games: Array(nintendoGames.prefix(10)),
                    icon: "gamecontroller"
                )
            }
        }
    }
}

// MARK: - Platform Detail View (특정 플랫폼 선택 시)
struct PlatformDetailView: View {
    let platform: PlatformFilterType
    let games: [Game]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 플랫폼 헤더
            HStack {
                Image(systemName: platformIcon)
                    .font(.title2)
                    .foregroundColor(platformColor)
                
                Text("\(platform.rawValue) 추천 게임")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(games.count)개")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            if games.isEmpty {
                EmptyPlatformView(platform: platform)
            } else {
                // 세로 스크롤 카드 리스트
                VStack(spacing: 16) {
                    ForEach(games) { game in
                        PlatformGameCard(game: game)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var platformIcon: String {
        switch platform {
            case .all:
                return "square.grid.2x2.fill"
            case .pc:
                return "desktopcomputer"
            case .playstation:
                return "playstation.logo"
            case .xbox:
                return "xbox.logo"
            case .nintendo:
                return "gamecontroller"
        }
    }
    
    private var platformColor: Color {
        platform.iconColor
    }
}

// MARK: - Platform Game Card (세로 스크롤용 카드)
struct PlatformGameCard: View {
    let game: Game
    @EnvironmentObject var favoriteManager: FavoriteManager
    
    var body: some View {
        HStack(spacing: 16) {
            // 게임 이미지
            ZStack(alignment: .topLeading) {
                if let coverURL = game.coverURL {
                    AsyncImage(url: coverURL) { phase in
                        switch phase {
                            case .empty:
                                PlatformCardPlaceholder()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                PlatformCardPlaceholder()
                            @unknown default:
                                PlatformCardPlaceholder()
                        }
                    }
                    .frame(width: 120, height: 160)
                    .cornerRadius(12)
                    .clipped()
                } else {
                    PlatformCardPlaceholder()
                }
                
                // 평점 배지
                if game.rating > 0 {
                    Text(String(format: "%.1f", game.rating))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow)
                        .cornerRadius(6)
                        .padding(8)
                }
            }
            
            // 게임 정보
            VStack(alignment: .leading, spacing: 8) {
                Text(game.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(game.genre)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // 플랫폼 아이콘
                HStack(spacing: 6) {
                    ForEach(game.platforms.prefix(4), id: \.rawValue) { platform in
                        Image(systemName: platform.iconName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            Spacer()
            
            // 즐겨찾기 버튼
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    favoriteManager.toggleFavorite(game: game)
                }
            }) {
                Image(systemName: favoriteManager.isFavorite(gameId: game.id) ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(.purple)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Platform Card Placeholder
struct PlatformCardPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 120, height: 160)
            .cornerRadius(12)
            .overlay(
                Image(systemName: "photo")
                    .font(.title)
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Empty Platform View
struct EmptyPlatformView: View {
    let platform: PlatformFilterType
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("\(platform.rawValue) 게임이 없습니다")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("다른 플랫폼을 선택해보세요")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.purple)
            
            Text("게임 정보를 불러오는 중...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("데이터를 불러올 수 없습니다")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("다시 시도")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.purple)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Game Section (한 줄 섹션)
struct GameSection: View {
    let title: String
    let games: [Game]
    var icon: String = "gamecontroller.fill"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if !games.isEmpty {
                    Text("\(games.count)개")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            if games.isEmpty {
                EmptyGameSection()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(games) { game in
                            GameCard(game: game)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Empty Game Section
struct EmptyGameSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("게임이 없습니다")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(favoriteManager: FavoriteManager())
            .environmentObject(FavoriteManager())
    }
}
