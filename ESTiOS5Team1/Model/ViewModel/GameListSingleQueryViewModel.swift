//
//  GameListSingleQueryViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/9/26.
//

import Foundation
import Combine

/// Discover / Trending / Genre 기반 단일 MultiQuery로
/// 게임 목록을 조회하는 ViewModel입니다.
///
/// - 화면 책임:
///   - 로딩 상태 표시
///   - 에러 표시
///   - 필터 결과 반영
///
/// - Domain 책임:
///   - 없음 (GameEntity가 담당)
///
/// - Networking 책임:
///   - 없음 (IGDBService가 담당)
///
/// - Important:
///   View에 표시되는 게임 목록(items)은 `GameListItem`이며,
///   필터링은 `GameEntity` 기준으로 수행한 뒤 가공합니다.
///
@MainActor
final class GameListSingleQueryViewModel: ObservableObject {

    @Published var items: [GameListItem] = []
    @Published var isLoading = false
    @Published var error: Error?

    private var entities: [GameEntity] = []
    private let service: IGDBService
    private let query: String

    init(service: IGDBService, query: String) {
        self.service = service
        self.query = query
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let batch = [
                IGDBBatchItem(name: "list", endpoint: .games, query: query)
            ]

            let sections = try await service.fetch(batch)

            if let raw = sections["list"] {
                let data = try JSONSerialization.data(withJSONObject: raw)
                let dto = try JSONDecoder().decode([IGDBGameListDTO].self, from: data)
                self.entities = dto.map(GameEntity.init)

                self.items = entities.map(GameListItem.init)
            }

        } catch {
            self.error = error
        }
    }

}
