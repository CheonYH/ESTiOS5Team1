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
            case .pinball: return "핀볼"
            case .adventure: return "어드벤처"
            case .arcade: return "아케이드"
            case .visualNovel: return "비주얼 노벨"
            case .cardBoard: return "카드/보드"
            case .moba: return "MOBA"
            case .pointAndClick: return "포인트 앤 클릭"
            case .fighting: return "격투"
            case .music: return "음악"
            case .platform: return "플랫포머"
            case .puzzle: return "퍼즐"
            case .shooter: return "슈팅"
            case .racing: return "레이싱"
            case .realTimeStrategy: return "실시간 전략"
            case .turnBasedStrategy: return "턴제 전략"
            case .rolePlaying: return "RPG"
            case .simulator: return "시뮬레이터"
            case .sport: return "스포츠"
            case .hackAndSlash: return "핵 앤 슬래시"
            case .quizTrivia: return "퀴즈"
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
