//
//  Genre.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/9/26.
//

import SwiftUI

// MARK: - Genre Filter Type
/// 검색 화면에서 사용하는 장르 필터 타입
/// GameGenreModel과 호환되도록 설계
enum GenreFilterType: String, CaseIterable, Identifiable {
    case all = "전체"
    case pinball = "Pinball"
    case adventure = "Adventure"
    case arcade = "Arcade"
    case visualNovel = "VisualNovel"
    case cardBoard = "CardBoard"
    case moba = "Moba"
    case pointAndClick = "PointAndClick"
    case fighting = "Fighting"
    case music = "Music"
    case platform = "Platform"
    case puzzle = "Puzzle"
    case shooter = "Shooter"
    case racing = "Racing"
    case realTimeStrategy = "RealTimeStrategy"
    case turnBasedStrategy = "TurnBasedStrategy"
    case rolePlaying = "RolePlaying"
    case simulator = "Simulator"
    case sport = "Sport"
    case hackAndSlash = "HackAndSlash"
    case quizTrivia = "QuizTrivia"

    var id: Self { self }

    /// 화면에 표시할 이름
    var displayName: String {
        switch self {
            case .all: return "전체"
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

    /// 장르 아이콘 (SF Symbols)
    var iconName: String {
        switch self {
            case .all: return "square.grid.2x2.fill"
            case .pinball: return "circle.circle"
            case .adventure: return "map.fill"
            case .arcade: return "arcade.stick"
            case .visualNovel: return "book.fill"
            case .cardBoard: return "rectangle.stack.fill"
            case .moba: return "person.3.fill"
            case .pointAndClick: return "cursorarrow.click"
            case .fighting: return "figure.boxing"
            case .music: return "music.note"
            case .platform: return "figure.run"
            case .puzzle: return "puzzlepiece.fill"
            case .shooter: return "scope"
            case .racing: return "car.fill"
            case .realTimeStrategy: return "clock.arrow.circlepath"
            case .turnBasedStrategy: return "arrow.triangle.2.circlepath"
            case .rolePlaying: return "shield.fill"
            case .simulator: return "airplane"
            case .sport: return "sportscourt.fill"
            case .hackAndSlash: return "bolt.fill"
            case .quizTrivia: return "questionmark.circle.fill"
        }
    }

    /// 장르 테마 색상
    var themeColor: Color {
        switch self {
            case .all: return .purple
            case .pinball: return .orange
            case .adventure: return .green
            case .arcade: return .yellow
            case .visualNovel: return .pink
            case .cardBoard: return .brown
            case .moba: return .red
            case .pointAndClick: return .cyan
            case .fighting: return .red
            case .music: return .purple
            case .platform: return .blue
            case .puzzle: return .teal
            case .shooter: return .orange
            case .racing: return .red
            case .realTimeStrategy: return .indigo
            case .turnBasedStrategy: return .mint
            case .rolePlaying: return .purple
            case .simulator: return .gray
            case .sport: return .green
            case .hackAndSlash: return .red
            case .quizTrivia: return .yellow
        }
    }

    /// IGDB API 장르 이름과 매칭하기 위한 키워드 목록
    var matchingKeywords: [String] {
        switch self {
            case .all: return []
            case .pinball: return ["pinball"]
            case .adventure: return ["adventure"]
            case .arcade: return ["arcade"]
            case .visualNovel: return ["visual novel", "visualnovel"]
            case .cardBoard: return ["card", "board"]
            case .moba: return ["moba"]
            case .pointAndClick: return ["point-and-click", "point and click"]
            case .fighting: return ["fighting"]
            case .music: return ["music", "rhythm"]
            case .platform: return ["platform", "platformer"]
            case .puzzle: return ["puzzle"]
            case .shooter: return ["shooter"]
            case .racing: return ["racing"]
            case .realTimeStrategy: return ["real time strategy", "rts", "real-time strategy"]
            case .turnBasedStrategy: return ["turn-based strategy", "turn based strategy", "tbs"]
            case .rolePlaying: return ["role-playing", "rpg", "role playing"]
            case .simulator: return ["simulator", "simulation"]
            case .sport: return ["sport"]
            case .hackAndSlash: return ["hack and slash", "hack-and-slash", "action rpg"]
            case .quizTrivia: return ["quiz", "trivia"]
        }
    }

    // swiftlint:disable cyclomatic_complexity

    /// GameGenreModel에서 GenreFilterType으로 변환
    static func from(gameGenre: GameGenreModel) -> GenreFilterType {
        switch gameGenre {
            case .pinball: return .pinball
            case .adventure: return .adventure
            case .arcade: return .arcade
            case .visualNovel: return .visualNovel
            case .cardBoard: return .cardBoard
            case .moba: return .moba
            case .pointAndClick: return .pointAndClick
            case .fighting: return .fighting
            case .music: return .music
            case .platform: return .platform
            case .puzzle: return .puzzle
            case .shooter: return .shooter
            case .racing: return .racing
            case .realTimeStrategy: return .realTimeStrategy
            case .turnBasedStrategy: return .turnBasedStrategy
            case .rolePlaying: return .rolePlaying
            case .simulator: return .simulator
            case .sport: return .sport
            case .hackAndSlash: return .hackAndSlash
            case .quizTrivia: return .quizTrivia
        }
    }

    // swiftlint:enable cyclomatic_complexity
}

// MARK: - Genre Matching
extension GenreFilterType {
    /// 게임의 장르 문자열이 이 필터 타입과 매칭되는지 확인
    func matches(genre: String) -> Bool {
        guard self != .all else { return true }

        let lowercasedGenre = genre.lowercased()
        return matchingKeywords.contains { keyword in
            lowercasedGenre.contains(keyword)
        }
    }
}
