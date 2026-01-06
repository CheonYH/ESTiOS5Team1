//
//  SearchView.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//

import SwiftUI

// MARK: - Models
struct Game: Identifiable {
    let id: String
    let title: String
    let genre: String
    let releaseYear: String
    let rating: Double
    let imageName: String
    let platforms: [Platform]
}

enum Platform: String {
    case playstation = "playstation"
    case xbox = "xbox"
    case pc = "pc"
    case nintendo = "nintendo"
    
    var icon: String {
        switch self {
            case .playstation: return "playstation.logo"
            case .xbox: return "xbox.logo"
            case .pc: return "pc"
            case .nintendo: return "nintendo.logo"
        }
    }
}

// MARK: - Dummy Data
struct DummyData {
    static let pcGames = [
        Game(id: "1", title: "Cyber Warck 2077", genre: "Action RPG", releaseYear: "2020", rating: 9.2, imageName: "game1", platforms: [.pc]),
        Game(id: "2", title: "The Witcher", genre: "Action RPG", releaseYear: "2015", rating: 9.2, imageName: "game2", platforms: [.pc]),
        Game(id: "3", title: "Parzowe", genre: "Action RPG", releaseYear: "2023", rating: 9.2, imageName: "game3", platforms: [.pc]),
        Game(id: "4", title: "Demon Seuls", genre: "Action Adventure", releaseYear: "2022", rating: 9.7, imageName: "game4", platforms: [.pc]),
        Game(id: "5", title: "The Medi", genre: "Action Adventure", releaseYear: "2021", rating: 9.2, imageName: "game5", platforms: [.pc])
    ]
    
    static let pinnedGames = [
        Game(
            id: "6",
            title: "Elden Ring Beterardk",
            genre: "Action RPG",
            releaseYear: "2022",
            rating: 9.3,
            imageName: "game6",
            platforms: [.pc, .playstation]
        ),
        Game(
            id: "7",
            title: "God of War Ragnarök",
            genre: "Action Adventure",
            releaseYear: "2022",
            rating: 9.3,
            imageName: "game7",
            platforms: [.playstation]
        ),
        Game(id: "8", title: "Fine Me", genre: "Action Adventure", releaseYear: "2023", rating: 9.4, imageName: "game8", platforms: [.pc])
    ]
    
    static let newReleases = [
        Game(
            id: "9",
            title: "Resident Evil 4 Remake"
            , genre: "Survival Horror",
            releaseYear: "2024",
            rating: 9.3,
            imageName: "game9",
            platforms: [.pc, .playstation]
        ),
        Game(
            id: "10",
            title: "Street Fighter 6",
            genre: "Fighting",
            releaseYear: "2024",
            rating: 9.8,
            imageName: "game10",
            platforms: [.pc, .playstation]
        ),
        Game(id: "11", title: "Starfield", genre: "RPG", releaseYear: "2024", rating: 8.5, imageName: "game11", platforms: [.pc, .xbox])
    ]
    
    static let comingSoon = [
        Game(
            id: "12",
            title: "Grand Theft Auto VI",
            genre: "Action Adventure",
            releaseYear: "2025",
            rating: 0.0,
            imageName: "game12",
            platforms: [.playstation, .xbox]
        )
    ]
    
    static let playstationGames = [
        Game(
            id: "13",
            title: "The Last of Us",
            genre: "Action Adventure",
            releaseYear: "2023",
            rating: 9.7,
            imageName: "game13",
            platforms: [.playstation]
        ),
        Game(
            id: "14",
            title: "Spider-Man 2",
            genre: "Action Adventure",
            releaseYear: "2023",
            rating: 9.4,
            imageName: "game14",
            platforms: [.playstation]
        )
    ]
}

// MARK: - SearchView
struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedPlatform: PlatformFilter = .all
    
    enum PlatformFilter: String, CaseIterable {
        case all = "전체"
        case pc = "PC"
        case playstation = "PlayStation"
        case xbox = "Xbox"
        case nintendo = "Nintendo"
        
        var iconColor: Color {
            switch self {
                case .all: return .purple
                case .pc: return .purple
                case .playstation: return .blue
                case .xbox: return .green
                case .nintendo: return .red
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Search Bar
                        searchBarSection
                        
                        // Platform Filter Buttons
                        platformFilterSection
                        
                        // PC 추천 게임
                        gameSectionWithHorizontalScroll(
                            title: "PC 추천 게임",
                            games: DummyData.pcGames
                        )
                        
                        // Pinned 게임
                        gameSectionWithHorizontalScroll(
                            title: "Pinned 게임",
                            games: DummyData.pinnedGames,
                            showLargeCard: true
                        )
                        
                        // New Releases 추천
                        newReleasesSection
                        
                        // Coming Soon
                        comingSoonSection
                        
                        // PlayStation 추천 게임
                        gameSectionWithHorizontalScroll(
                            title: "PlayStation 추천 게임",
                            games: DummyData.playstationGames
                        )
                    }
                    .padding(.bottom, 80)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(.purple)
                            Text("GameVault")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Search Bar Section
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("게임 포털, 태그 검색...", text: $searchText)
                .foregroundColor(.white)
                .placeholder(when: searchText.isEmpty) {
                    Text("게임 포털, 태그 검색...")
                        .foregroundColor(.gray)
                }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Platform Filter Section
    private var platformFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PlatformFilter.allCases, id: \.self) { platform in
                    PlatformButton(
                        platform: platform,
                        isSelected: selectedPlatform == platform
                    ) {
                        selectedPlatform = platform
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Game Section with Horizontal Scroll
    private func gameSectionWithHorizontalScroll(title: String, games: [Game], showLargeCard: Bool = false) -> some View {
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
    
    // MARK: - New Releases Section
    private var newReleasesSection: some View {
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
    
    // MARK: - Coming Soon Section
    private var comingSoonSection: some View {
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

// MARK: - Platform Button
struct PlatformButton: View {
    let platform: SearchView.PlatformFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                platformIcon
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? platform.iconColor : Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var platformIcon: some View {
        switch platform {
            case .all:
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundColor(.white)
            case .pc:
                Image(systemName: "desktopcomputer")
                    .foregroundColor(.white)
            case .playstation:
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.white)
            case .xbox:
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.white)
            case .nintendo:
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.white)
        }
    }
}

// MARK: - Game Card
struct GameCard: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                // Game Image
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 140, height: 200)
                    .cornerRadius(12)
                
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
                        .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(game.genre)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: 140)
        }
    }
}

// MARK: - Large Game Card
struct LargeGameCard: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                // Game Image
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 180, height: 260)
                    .cornerRadius(12)
                
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
                        .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(game.genre)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: 180)
        }
    }
}

// MARK: - New Release Card
struct NewReleaseCard: View {
    let game: Game
    
    var body: some View {
        HStack(spacing: 16) {
            // Game Image
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 100, height: 140)
                .cornerRadius(12)
            
            // Game Info
            VStack(alignment: .leading, spacing: 8) {
                Text(game.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(game.genre + " • " + game.releaseYear)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Rating and Platforms
                HStack(spacing: 8) {
                    // Rating
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
                    
                    // Platform Icons
                    HStack(spacing: 4) {
                        ForEach(game.platforms, id: \.rawValue) { platform in
                            Image(systemName: "gamecontroller.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
            }
            
            Spacer()
            
            // Add Button
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.purple)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Coming Soon Card
struct ComingSoonCard: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Game Image
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 280, height: 350)
                    .cornerRadius(12)
                
                // Coming Soon Badge
                Text(game.releaseYear)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple)
                    .cornerRadius(8)
                    .padding(12)
            }
            
            // Game Info Overlay
            VStack(alignment: .leading, spacing: 8) {
                Text(game.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Image(systemName: "playstation.logo")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("TRA")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Platform Icons Row
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "house.fill")
                            .foregroundColor(.purple)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "rectangle.stack.fill")
                            .foregroundColor(.gray)
                    }
                }
                .font(.title3)
            }
            .padding(16)
            .frame(width: 280)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .offset(y: -50)
        }
    }
}

// MARK: - View Extension for Placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
