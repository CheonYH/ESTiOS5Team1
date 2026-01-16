//
//  SearchView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
//  [수정] Game → GameListItem 통일

import SwiftUI

// MARK: - Search View
struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedPlatform: PlatformFilterType
    @State private var selectedGenre: GenreFilterType
    @State private var isSearchActive = false

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
        // [수정] NavigationView → NavigationStack으로 변경
        // 탭 전환 후 돌아올 때 navigation bar가 사라지는 문제 해결 (iOS 16+)
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        // 검색바 (조건부 표시)
                        if isSearchActive {
                            SearchBar(searchText: $searchText, isSearchActive: $isSearchActive)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Platform Filter (고정)
                        PlatformFilter(selectedPlatform: $selectedPlatform)
                            .padding(.top, 10)

                        // Genre Filter (고정, 하단 구분선 포함)
                        // [수정] games → items
                        GenreFilter(selectedGenre: $selectedGenre, items: allItems)
                            .padding(.top, 10)

                        // 게임 카드만 스크롤
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                // 스크롤 상단 앵커
                                Color.clear
                                    .frame(height: 1)
                                    .id("top")

                                // [수정] 로딩 또는 에러 상태 - discoverGames → discoverItems
                                if viewModel.isLoading && viewModel.discoverItems.isEmpty {
                                    LoadingView()
                                } else if let error = viewModel.error, viewModel.discoverItems.isEmpty {
                                    ErrorView(error: error) {
                                        Task { await viewModel.loadAllGames() }
                                    }
                                } else {
                                    // 결과 헤더
                                    ResultHeader(
                                        title: headerTitle,
                                        count: filteredItems.count
                                    )
                                    .padding(.top, 10)

                                    // 2열 그리드 게임 카드
                                    // [수정] filteredGames → filteredItems
                                    if filteredItems.isEmpty {
                                        EmptyFilterResultView(
                                            platform: selectedPlatform,
                                            genre: selectedGenre
                                        )
                                    } else {
                                        GameGridView(items: filteredItems)
                                    }
                                }
                            }
                            
                            .padding(.bottom, 10)
                        }
                        .refreshable {
                            await viewModel.loadAllGames()
                        }
                        // 장르 변경 시 상단으로 스크롤
                        .onChange(of: selectedGenre) { _ in
                            withAnimation(.spring(response: 0.4)) {
                                proxy.scrollTo("top", anchor: .top)
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
        }
        // [수정] discoverGames → discoverItems
        .onAppear {
            if viewModel.discoverItems.isEmpty {
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

    // [수정] 모든 게임 (중복 제거, 순서 유지) - Game → GameListItem
    private var allItems: [GameListItem] {
        let items = viewModel.discoverItems + viewModel.trendingItems + viewModel.newReleaseItems
        var seen = Set<Int>()
        return items.filter { item in
            if seen.contains(item.id) { return false }
            seen.insert(item.id)
            return true
        }
    }

    // [수정] filteredGames → filteredItems
    private var filteredItems: [GameListItem] {
        allItems.filter { item in
            let matchesPlatform = filterByPlatform(item: item, platform: selectedPlatform)
            let matchesGenre = filterByGenre(item: item, genre: selectedGenre)
            let matchesSearch = searchText.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.genre.joined(separator: " ").localizedCaseInsensitiveContains(searchText)

            return matchesPlatform && matchesGenre && matchesSearch
        }
    }

    // MARK: - Helper Methods

    // [수정] game → item, platforms → platformCategories
    private func filterByPlatform(item: GameListItem, platform: PlatformFilterType) -> Bool {
        guard platform != .all else { return true }

        return item.platformCategories.contains { itemPlatform in
            switch platform {
            case .all: return true
            case .pc: return itemPlatform == .pc
            case .playstation: return itemPlatform == .playstation
            case .xbox: return itemPlatform == .xbox
            case .nintendo: return itemPlatform == .nintendo
            }
        }
    }

    // [수정] game → item, genre가 배열이므로 any로 매칭
    private func filterByGenre(item: GameListItem, genre: GenreFilterType) -> Bool {
        guard genre != .all else { return true }
        return item.genre.contains { genreString in
            genre.matches(genre: genreString)
        }
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
// [수정] games → items, Game → GameListItem
struct GameGridView: View {
    let items: [GameListItem]
    @EnvironmentObject var favoriteManager: FavoriteManager

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items, id: \.id) { item in
                GameListCard(
                    item: item,
                    isFavorite: favoriteManager.isFavorite(itemId: item.id),
                    onToggleFavorite: {
                        favoriteManager.toggleFavorite(item: item)
                    }
                )
            }
        }
        .padding(.horizontal)
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
