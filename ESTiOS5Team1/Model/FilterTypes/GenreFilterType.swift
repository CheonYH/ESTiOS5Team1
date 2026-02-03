//
//  Genre.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/9/26.
//

import SwiftUI

// MARK: - Genre Filter Type

/// 검색 화면에서 사용하는 장르 필터 타입입니다.
///
/// - Responsibilities:
///     - 게임 장르별 필터링 조건 정의
///     - UI 표시용 이름, 아이콘, 색상 제공
///     - IGDB API 장르 ID 및 키워드 매핑
///     - `GameGenreModel`과의 호환성 제공
///
/// - Important:
///     IGDB API의 장르 ID를 사용하여 서버 사이드 필터링을 지원합니다.
///     각 장르는 `matchingKeywords`를 통해 다양한 장르 표기와 매칭됩니다.
///
/// - Example:
///     ```swift
///     let selectedGenre: GenreFilterType = .rolePlaying
///
///     // UI 표시
///     Text(selectedGenre.displayName)  // "RPG"
///     Image(systemName: selectedGenre.iconName)
///
///     // 필터링
///     if selectedGenre.matches(genre: "Role-playing") { ... }
///     ```
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

    /// [추가] IGDB API 장르 ID (서버 사이드 필터링용)
    /// 참고: https://api-docs.igdb.com/#genre
    var igdbGenreId: Int? {
        switch self {
            case .all: return nil  // 전체는 ID 없음
            case .pinball: return 30
            case .adventure: return 31
            case .arcade: return 33
            case .visualNovel: return 34
            case .cardBoard: return 35
            case .moba: return 36
            case .pointAndClick: return 2
            case .fighting: return 4
            case .music: return 7
            case .platform: return 8
            case .puzzle: return 9
            case .shooter: return 5
            case .racing: return 10
            case .realTimeStrategy: return 11
            case .turnBasedStrategy: return 16
            case .rolePlaying: return 12
            case .simulator: return 13
            case .sport: return 14
            case .hackAndSlash: return 25
            case .quizTrivia: return 26
        }
    }

    // swiftlint:disable cyclomatic_complexity

    /// `GameGenreModel`을 `GenreFilterType`으로 변환합니다.
    ///
    /// - Parameter gameGenre: 변환할 `GameGenreModel` 값
    /// - Returns: 대응하는 `GenreFilterType` 값
    ///
    /// - Note:
    ///     홈 화면의 장르 버튼에서 검색 화면으로 이동할 때 사용됩니다.
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
