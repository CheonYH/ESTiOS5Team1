//
//  FavoriteManager.swift
//  ESTiOS5Team1
//
//  Created by 이찬희 on 1/6/26.
//
//  [수정] Game → GameListItem 통일
//  [리팩토링] FavoriteManagerProtocol 채택

import SwiftUI
import Combine

// MARK: - Favorite Manager

/// 게임 즐겨찾기(라이브러리) 기능을 관리하는 매니저 클래스입니다.
/// UserDefaults를 통해 즐겨찾기 상태를 영구 저장합니다.
@MainActor
class FavoriteManager: ObservableObject, FavoriteManagerProtocol {

    // MARK: - Published Properties

    /// 즐겨찾기된 게임 ID 집합입니다.
    @Published var favoriteItemIds: Set<Int> = []

    // MARK: - Private Properties

    /// 로드된 모든 게임 데이터를 저장합니다.
    /// 즐겨찾기한 게임의 상세 정보를 제공하기 위해 캐싱합니다.
    private var allItems: [GameListItem] = []

    // MARK: - Initialization

    /// UserDefaults에서 저장된 즐겨찾기를 로드하여 초기화합니다.
    init() {
        loadFavorites()
    }

    // MARK: - Public Methods

    /// 게임 아이템 목록을 내부 캐시에 추가합니다.
    /// - Parameter items: 추가할 게임 아이템 배열
    func updateItems(_ items: [GameListItem]) {
        let existingIds = Set(allItems.map { $0.id })
        let newItems = items.filter { !existingIds.contains($0.id) }
        allItems.append(contentsOf: newItems)
    }

    /// 게임의 즐겨찾기 상태를 토글합니다.
    /// - Parameter item: 즐겨찾기 상태를 변경할 게임 아이템
    func toggleFavorite(item: GameListItem) {
        if favoriteItemIds.contains(item.id) {
            favoriteItemIds.remove(item.id)
        } else {
            favoriteItemIds.insert(item.id)
            if !allItems.contains(where: { $0.id == item.id }) {
                allItems.append(item)
            }
        }
        saveFavorites()
    }

    /// 특정 게임이 즐겨찾기되어 있는지 확인합니다.
    ///
    /// - Parameter itemId: 확인할 게임 ID
    /// - Returns: 즐겨찾기 여부
    func isFavorite(itemId: Int) -> Bool {
        return favoriteItemIds.contains(itemId)
    }

    /// 즐겨찾기된 게임 아이템 목록을 반환합니다.
    ///
    /// - Returns: 즐겨찾기된 `GameListItem` 배열
    var favoriteItems: [GameListItem] {
        return allItems.filter { favoriteItemIds.contains($0.id) }
    }

    // MARK: - Private Methods

    /// 즐겨찾기 ID 목록을 UserDefaults에 저장합니다.
    private func saveFavorites() {
        let array = Array(favoriteItemIds)
        UserDefaults.standard.set(array, forKey: "favoriteItemIds")
    }

    /// UserDefaults에서 즐겨찾기 ID 목록을 로드합니다.
    private func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: "favoriteItemIds") as? [Int] {
            favoriteItemIds = Set(saved)
        }
    }
}
