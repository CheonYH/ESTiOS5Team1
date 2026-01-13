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
    @State private var selectedPlatform: PlatformFilterType
    @State private var selectedGenre: GenreFilterType
    @State private var isSearchActive = false
    @State private var showScrollButton = false

    @StateObject private var viewModel: SearchViewModel
    @EnvironmentObject var favoriteManager: FavoriteManager

    // MARK: - Initialization

    init(favoriteManager: FavoriteManager) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(favoriteManager: favoriteManager))
        _selectedPlatform = State(initialValue: .all)
        _selectedGenre = State(initialValue: .all)
    }

    init(favoriteManager: FavoriteManager, initialGenre: GenreFilterType) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(favoriteManager: favoriteManager))
        _selectedPlatform = State(initialValue: .all)
        _selectedGenre = State(initialValue: initialGenre)
    }

    init(
        favoriteManager: FavoriteManager,
        initialGenre: GenreFilterType,
        initialPlatform: PlatformFilterType
    ) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(favoriteManager: favoriteManager))
        _selectedPlatform = State(initialValue: initialPlatform)
        _selectedGenre = State(initialValue: initialGenre)
    }

    init(favoriteManager: FavoriteManager, gameGenre: GameGenreModel) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(favoriteManager: favoriteManager))
        _selectedPlatform = State(initialValue: .all)
        _selectedGenre = State(initialValue: GenreFilterType.from(gameGenre: gameGenre))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        // 검색바 (조건부 표시)
                        if isSearchActive {
                            SearchBar(searchText: $searchText, isSearchActive: $isSearchActive)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                // 스크롤 상단 앵커
                                Color.clear
                                    .frame(height: 1)
                                    .id("top")

                                // Platform Filter
                                PlatformFilter(selectedPlatform: $selectedPlatform)
                                    .padding(.top, 8)

                                // Genre Filter (텍스트 스타일, 가로 스크롤 + 하단 구분선 통합)
                                GenreFilter(selectedGenre: $selectedGenre, games: allGames)

                                // 로딩 또는 에러 상태
                                if viewModel.isLoading && viewModel.discoverGames.isEmpty {
                                    LoadingView()
                                } else if let error = viewModel.error, viewModel.discoverGames.isEmpty {
                                    ErrorView(error: error) {
                                        Task { await viewModel.loadAllGames() }
                                    }
                                } else {
                                    // 결과 헤더
                                    ResultHeader(
                                        title: headerTitle,
                                        count: filteredGames.count
                                    )
                                    .padding(.top, 8)

                                    // 2열 그리드 게임 카드
                                    if filteredGames.isEmpty {
                                        EmptyFilterResultView(
                                            platform: selectedPlatform,
                                            genre: selectedGenre
                                        )
                                    } else {
                                        GameGridView(
                                            games: filteredGames,
                                            onScrolled: { isScrolled in
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    showScrollButton = isScrolled
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.bottom, 100)
                        }
                        .refreshable {
                            await viewModel.loadAllGames()
                        }
                        // 상단으로 이동 버튼 (스크롤 시에만 표시)
                        .overlay(alignment: .bottom) {
                            if showScrollButton {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4)) {
                                        proxy.scrollTo("top", anchor: .top)
                                    }
                                }) {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color.purple.opacity(0.7))
                                        .clipShape(Circle())
                                }
                                .padding(.bottom, 20)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("추천 검색")
                        .font(.title2)
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
                Task { await viewModel.loadAllGames() }
            }
        }
    }

    // MARK: - Computed Properties

    private var hasActiveFilters: Bool {
        selectedPlatform != .all || selectedGenre != .all || !searchText.isEmpty
    }

    private var headerTitle: String {
        var components: [String] = []

        if selectedPlatform != .all {
            components.append(selectedPlatform.rawValue)
        }

        if selectedGenre != .all {
            components.append(selectedGenre.displayName)
        }

        if components.isEmpty {
            return "추천 게임"
        }

        return components.joined(separator: " · ") + " 게임"
    }

    // 모든 게임 (중복 제거, 순서 유지)
    private var allGames: [Game] {
        let games = viewModel.discoverGames + viewModel.trendingGames + viewModel.newReleaseGames
        var seen = Set<String>()
        return games.filter { game in
            if seen.contains(game.id) { return false }
            seen.insert(game.id)
            return true
        }
    }

    private var filteredGames: [Game] {
        allGames.filter { game in
            let matchesPlatform = filterByPlatform(game: game, platform: selectedPlatform)
            let matchesGenre = filterByGenre(game: game, genre: selectedGenre)
            let matchesSearch = searchText.isEmpty ||
                game.title.localizedCaseInsensitiveContains(searchText) ||
                game.genre.localizedCaseInsensitiveContains(searchText)

            return matchesPlatform && matchesGenre && matchesSearch
        }
    }

    // MARK: - Helper Methods

    private func filterByPlatform(game: Game, platform: PlatformFilterType) -> Bool {
        guard platform != .all else { return true }

        return game.platforms.contains { gamePlatform in
            switch platform {
            case .all: return true
            case .pc: return gamePlatform == .pc
            case .playstation: return gamePlatform == .playstation
            case .xbox: return gamePlatform == .xbox
            case .nintendo: return gamePlatform == .nintendo
            }
        }
    }

    private func filterByGenre(game: Game, genre: GenreFilterType) -> Bool {
        guard genre != .all else { return true }
        return genre.matches(genre: game.genre)
    }
}

// MARK: - Result Header
struct ResultHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: "gamecontroller.fill")
                .foregroundColor(.purple)

            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            Text("\(count)개")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
}

// MARK: - Game Grid View (2열 세로 스크롤)
struct GameGridView: View {
    let games: [Game]
    var onScrolled: ((Bool) -> Void)?
    @EnvironmentObject var favoriteManager: FavoriteManager

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                CompactGameCard(
                    game: game,
                    isFavorite: favoriteManager.isFavorite(gameId: game.id),
                    onToggleFavorite: {
                        favoriteManager.toggleFavorite(game: game)
                    }
                )
                .onAppear {
                    // 첫 번째 게임이 보이면 (상단에 있음) 버튼 숨김
                    if index == 0 {
                        onScrolled?(false)
                    }
                }
                .onDisappear {
                    // 첫 번째 게임이 사라지면 (스크롤 내림) 버튼 표시
                    if index == 0 {
                        onScrolled?(true)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Compact Game Card (그리드용 컴팩트 카드)
struct CompactGameCard: View {
    let game: Game
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 게임 이미지
            ZStack(alignment: .topLeading) {
                if let coverURL = game.coverURL {
                    AsyncImage(url: coverURL) { phase in
                        switch phase {
                        case .empty:
                            CardPlaceholder()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            CardPlaceholder()
                        @unknown default:
                            CardPlaceholder()
                        }
                    }
                    .frame(height: 225)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(12)
                } else {
                    CardPlaceholder()
                }

                // 평점 배지
                if game.rating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text(String(format: "%.1f", game.rating))
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .cornerRadius(8)
                    .padding(8)
                }

                // 즐겨찾기 버튼
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: onToggleFavorite) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 14))
                                .foregroundColor(isFavorite ? .red : .white)
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(8)
                    }
                }
                .frame(height: 225)
            }

            // 게임 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(game.genre)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)

                // 플랫폼 아이콘
                HStack(spacing: 4) {
                    ForEach(game.platforms.prefix(3), id: \.rawValue) { platform in
                        Image(systemName: platform.iconName)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    if game.platforms.count > 3 {
                        Text("+\(game.platforms.count - 3)")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .background(Color.clear)
    }
}

// MARK: - Card Placeholder
struct CardPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(height: 225)
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
            .overlay(
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Active Filters Bar
struct ActiveFiltersBar: View {
    @Binding var selectedPlatform: PlatformFilterType
    @Binding var selectedGenre: GenreFilterType
    @Binding var searchText: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if selectedPlatform != .all {
                    FilterChip(
                        label: selectedPlatform.rawValue,
                        color: selectedPlatform.iconColor
                    ) {
                        withAnimation { selectedPlatform = .all }
                    }
                }

                if selectedGenre != .all {
                    FilterChip(
                        label: selectedGenre.displayName,
                        color: selectedGenre.themeColor
                    ) {
                        withAnimation { selectedGenre = .all }
                    }
                }

                if !searchText.isEmpty {
                    FilterChip(
                        label: "\"\(searchText)\"",
                        color: .blue
                    ) {
                        withAnimation { searchText = "" }
                    }
                }

                // 전체 초기화 버튼
                Button(action: {
                    withAnimation {
                        selectedPlatform = .all
                        selectedGenre = .all
                        searchText = ""
                    }
                }) {
                    Text("초기화")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.8))
        .clipShape(Capsule())
    }
}

// MARK: - Empty Filter Result View
struct EmptyFilterResultView: View {
    let platform: PlatformFilterType
    let genre: GenreFilterType

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("검색 결과가 없습니다")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text(suggestionText)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var suggestionText: String {
        if platform != .all && genre != .all {
            return "\(platform.rawValue)에서 \(genre.displayName) 장르의 게임을 찾지 못했습니다.\n다른 조합을 시도해보세요."
        } else if platform != .all {
            return "\(platform.rawValue) 플랫폼의 게임을 찾지 못했습니다."
        } else if genre != .all {
            return "\(genre.displayName) 장르의 게임을 찾지 못했습니다."
        }
        return "다른 검색어를 시도해보세요."
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

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SearchView(favoriteManager: FavoriteManager())
                .environmentObject(FavoriteManager())
                .previewDisplayName("기본")

            SearchView(favoriteManager: FavoriteManager(), initialGenre: .shooter)
                .environmentObject(FavoriteManager())
                .previewDisplayName("장르 선택됨")
        }
    }
}
