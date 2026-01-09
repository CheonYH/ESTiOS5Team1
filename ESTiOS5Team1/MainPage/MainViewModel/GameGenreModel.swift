//
//  GameGenreModel.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/8/26.
//

import Foundation

enum GameGenreModel: CaseIterable, Identifiable {
    case pinball
    case adventure
    case arcade
    case visualNovel
    case cardBoard
    case moba
    case pointAndClick
    case fighting
    case music
    case platform
    case puzzle
    case shooter
    case racing
    case realTimeStrategy
    case turnBasedStrategy
    case rolePlaying
    case simulator
    case sport
    case hackAndSlash
    case quizTrivia

    var id: Self { self }

    var displayName: String {
        switch self {
        case .pinball:
            return "Pinball"
        case .adventure:
            return "Adventure"
        case .arcade:
            return "Arcade"
        case .visualNovel:
            return "VisualNovel"
        case .cardBoard:
            return "CardBoard"
        case .moba:
            return "Moba"
        case .pointAndClick:
            return "PointAndClick"
        case .fighting:
            return "Fighting"
        case .music:
            return "Music"
        case .platform:
            return "Platform"
        case .puzzle:
            return "Puzzle"
        case .shooter:
            return "Shooter"
        case .racing:
            return "Racing"
        case .realTimeStrategy:
            return "RealTimeStrategy"
        case .turnBasedStrategy:
            return "TurnBasedStrategy"
        case .rolePlaying:
            return "RolePlaying"
        case .simulator:
            return "Simulator"
        case .sport:
            return "Sport"
        case .hackAndSlash:
            return "HackAndSlash"
        case .quizTrivia:
            return "QuizTrivia"
        }
    }

    var imageName: String {
        switch self {
        case .pinball:
            return "genre_pinball"
        case .adventure:
            return "genre_adventure"
        case .arcade:
            return "genre_arcade"
        case .visualNovel:
            return "genre_visualNovel"
        case .cardBoard:
            return "genre_card_board"
        case .moba:
            return "genre_moba"
        case .pointAndClick:
            return "genre_point-and-click"
        case .fighting:
            return "genre_fighting"
        case .music:
            return "genre_music"
        case .platform:
            return "genre_platform"
        case .puzzle:
            return "genre_puzzle"
        case .shooter:
            return "genre_shooter"
        case .racing:
            return "genre_racing"
        case .realTimeStrategy:
            return "genre_realTimeStrategy"
        case .turnBasedStrategy:
            return "genre_turnBasedStrategy"
        case .rolePlaying:
            return "genre_rolePlaying"
        case .simulator:
            return "genre_simulator"
        case .sport:
            return "genre_sport"
        case .hackAndSlash:
            return "genre_hackAndSlash"
        case .quizTrivia:
            return "genre_quiz_trivia"
        }
    }
}
