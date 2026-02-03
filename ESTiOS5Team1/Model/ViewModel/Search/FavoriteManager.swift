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
///
/// - Responsibilities:
///     - 즐겨찾기 게임 ID 관리 (추가/제거/조회)
///     - UserDefaults를 통한 즐겨찾기 영구 저장
///     - 로드된 게임 데이터 캐싱 (즐겨찾기 상세 정보 제공용)
///
/// - Important:
///     - `@MainActor`로 선언되어 UI 업데이트가 메인 스레드에서 수행됩니다.
///     - `FavoriteManagerProtocol`을 채택하여 테스트 및 의존성 주입이 가능합니다.
///     - 앱 전역에서 `@EnvironmentObject`로 공유됩니다.
///
/// - Example:
///     ```swift
///     @EnvironmentObject var favoriteManager: FavoriteManager
///
///     // 즐겨찾기 토글
///     favoriteManager.toggleFavorite(item: gameItem)
///
///     // 즐겨찾기 여부 확인
///     if favoriteManager.isFavorite(itemId: gameItem.id) { ... }
///     ```
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
    ///
    /// - Parameter items: 추가할 게임 아이템 배열
    ///
    /// - Note:
    ///     중복된 ID를 가진 아이템은 무시됩니다.
    ///     SearchViewModel에서 게임 로드 시 호출됩니다.
    func updateItems(_ items: [GameListItem]) {
        let existingIds = Set(allItems.map { $0.id })
        let newItems = items.filter { !existingIds.contains($0.id) }
        allItems.append(contentsOf: newItems)
    }

    /// 게임의 즐겨찾기 상태를 토글합니다.
    ///
    /// - Parameter item: 즐겨찾기 상태를 변경할 게임 아이템
    ///
    /// - Effects:
    ///     - 이미 즐겨찾기된 경우: 목록에서 제거
    ///     - 즐겨찾기되지 않은 경우: 목록에 추가 및 캐시 저장
    ///     - UserDefaults에 변경사항 저장
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
