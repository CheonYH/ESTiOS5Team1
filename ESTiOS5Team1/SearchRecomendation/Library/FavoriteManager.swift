//
//  FavoriteManager.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
//  [수정] Game → GameListItem 통일

import SwiftUI
import Combine

// MARK: - Favorite Manager
@MainActor
class FavoriteManager: ObservableObject {
    // [수정] Set<String> → Set<Int> (GameListItem.id는 Int)
    @Published var favoriteItemIds: Set<Int> = []

    // [수정] 현재 로드된 모든 게임 데이터를 저장
    private var allItems: [GameListItem] = []

    init() {
        // UserDefaults에서 저장된 즐겨찾기 로드
        loadFavorites()
    }

    // MARK: - Public Methods

    // [수정] 게임 목록 업데이트 (ViewModel에서 호출)
    func updateItems(_ items: [GameListItem]) {
        // 기존 게임과 새 게임을 합침 (중복 제거)
        let existingIds = Set(allItems.map { $0.id })
        let newItems = items.filter { !existingIds.contains($0.id) }
        allItems.append(contentsOf: newItems)
    }

    // [수정] 즐겨찾기 추가/제거
    func toggleFavorite(item: GameListItem) {
        if favoriteItemIds.contains(item.id) {
            favoriteItemIds.remove(item.id)
        } else {
            favoriteItemIds.insert(item.id)
            // 게임이 allItems에 없으면 추가
            if !allItems.contains(where: { $0.id == item.id }) {
                allItems.append(item)
            }
        }
        saveFavorites()
    }

    // [수정] 즐겨찾기 여부 확인
    func isFavorite(itemId: Int) -> Bool {
        return favoriteItemIds.contains(itemId)
    }

    // [수정] 즐겨찾기한 게임 목록 반환
    var favoriteItems: [GameListItem] {
        return allItems.filter { favoriteItemIds.contains($0.id) }
    }

    // MARK: - Private Methods

    private func saveFavorites() {
        let array = Array(favoriteItemIds)
        UserDefaults.standard.set(array, forKey: "favoriteItemIds")
    }

    private func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: "favoriteItemIds") as? [Int] {
            favoriteItemIds = Set(saved)
        }
    }
}
