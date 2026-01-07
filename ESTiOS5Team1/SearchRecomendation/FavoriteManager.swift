//
//  FavoriteManager.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
import SwiftUI
import Combine

// MARK: - Favorite Manager
class FavoriteManager: ObservableObject {
    @Published var favoriteGameIds: Set<String> = []
    
    // 모든 게임 데이터를 저장
    private var allGames: [Game] = []
    
    init() {
        // 더미 데이터 초기화
        allGames = DummyData.pcGames + DummyData.pinnedGames + DummyData.newReleases + DummyData.comingSoon + DummyData.playstationGames
    }
    
    // 즐겨찾기 추가/제거
    func toggleFavorite(game: Game) {
        if favoriteGameIds.contains(game.id) {
            favoriteGameIds.remove(game.id)
        } else {
            favoriteGameIds.insert(game.id)
        }
    }
    
    // 즐겨찾기 여부 확인
    func isFavorite(gameId: String) -> Bool {
        return favoriteGameIds.contains(gameId)
    }
    
    // 즐겨찾기한 게임 목록 반환
    var favoriteGames: [Game] {
        return allGames.filter { favoriteGameIds.contains($0.id) }
    }
}
