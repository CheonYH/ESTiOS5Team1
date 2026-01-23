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

    /// 화면에 표시할 리스트 아이템입니다.
    @Published var items: [GameListItem] = []
    /// 로딩 상태입니다.
    @Published var isLoading = false
    /// 에러 상태입니다.
    @Published var error: Error?

    /// 원본 엔티티 캐시입니다. (필터링용)
    private var entities: [GameEntity] = []
    /// IGDB API 서비스입니다.
    private let service: IGDBService
    /// 멀티쿼리 본문입니다.
    private let query: String

    /// 서비스와 쿼리를 주입받습니다.
    init(service: IGDBService, query: String) {
        self.service = service
        self.query = query
    }

    /// 단일 멀티쿼리로 게임 목록을 불러옵니다.
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
