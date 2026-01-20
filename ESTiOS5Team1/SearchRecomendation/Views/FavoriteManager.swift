//
//  FavoriteManager.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
import SwiftUI
import Combine

// MARK: - Favorite Manager
@MainActor
class FavoriteManager: ObservableObject {
    @Published var favoriteGameIds: Set<String> = []

    // 현재 로드된 모든 게임 데이터를 저장
    private var allGames: [Game] = []

    init() {
        // UserDefaults에서 저장된 즐겨찾기 로드
        loadFavorites()
    }

    // MARK: - Public Methods

    /// 게임 목록 업데이트 (ViewModel에서 호출)
    func updateGames(_ games: [Game]) {
        // 기존 게임과 새 게임을 합침 (중복 제거)
        let existingIds = Set(allGames.map { $0.id })
        let newGames = games.filter { !existingIds.contains($0.id) }
        allGames.append(contentsOf: newGames)
    }

    /// 즐겨찾기 추가/제거
    func toggleFavorite(game: Game) {
        if favoriteGameIds.contains(game.id) {
            favoriteGameIds.remove(game.id)
        } else {
            favoriteGameIds.insert(game.id)
            // 게임이 allGames에 없으면 추가
            if !allGames.contains(where: { $0.id == game.id }) {
                allGames.append(game)
            }
        }
        saveFavorites()
    }

    /// 즐겨찾기 여부 확인
    func isFavorite(gameId: String) -> Bool {
        return favoriteGameIds.contains(gameId)
    }

    /// 즐겨찾기한 게임 목록 반환
    var favoriteGames: [Game] {
        return allGames.filter { favoriteGameIds.contains($0.id) }
    }

    // MARK: - Private Methods

    private func saveFavorites() {
        let array = Array(favoriteGameIds)
        UserDefaults.standard.set(array, forKey: "favoriteGameIds")
    }

    private func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: "favoriteGameIds") as? [String] {
            favoriteGameIds = Set(saved)
        }
    }
}
