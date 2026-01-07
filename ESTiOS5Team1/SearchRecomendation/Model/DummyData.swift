//
//  DummyData.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/7/26.
//


import Foundation

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
        Game(id: "6", title: "Elden Ring Beterardk", genre: "Action RPG", releaseYear: "2022", rating: 9.3, imageName: "game6", platforms: [.pc, .playstation]),
        Game(id: "7", title: "God of War Ragnarök", genre: "Action Adventure", releaseYear: "2022", rating: 9.3, imageName: "game7", platforms: [.playstation]),
        Game(id: "8", title: "Fine Me", genre: "Action Adventure", releaseYear: "2023", rating: 9.4, imageName: "game8", platforms: [.pc])
    ]
    
    static let newReleases = [
        Game(id: "9", title: "Resident Evil 4 Remake", genre: "Survival Horror", releaseYear: "2024", rating: 9.3, imageName: "game9", platforms: [.pc, .playstation]),
        Game(id: "10", title: "Street Fighter 6", genre: "Fighting", releaseYear: "2024", rating: 9.8, imageName: "game10", platforms: [.pc, .playstation]),
        Game(id: "11", title: "Starfield", genre: "RPG", releaseYear: "2024", rating: 8.5, imageName: "game11", platforms: [.pc, .xbox])
    ]
    
    static let comingSoon = [
        Game(id: "12", title: "Grand Theft Auto VI", genre: "Action Adventure", releaseYear: "2025", rating: 0.0, imageName: "game12", platforms: [.playstation, .xbox])
    ]
    
    static let playstationGames = [
        Game(id: "13", title: "The Last of Us", genre: "Action Adventure", releaseYear: "2023", rating: 9.7, imageName: "game13", platforms: [.playstation]),
        Game(id: "14", title: "Spider-Man 2", genre: "Action Adventure", releaseYear: "2023", rating: 9.4, imageName: "game14", platforms: [.playstation])
    ]
}