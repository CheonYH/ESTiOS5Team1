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
    /// 추가 페이지 로딩 상태입니다.
    @Published var isLoadingMore = false
    /// 에러 상태입니다.
    @Published var error: Error?

    /// 원본 엔티티 캐시입니다. (필터링용)
    private var entities: [GameEntity] = []
    /// IGDB API 서비스입니다.
    private let service: IGDBService
    /// 멀티쿼리 본문입니다.
    private let query: String
    /// 페이지 당 요청 크기입니다.
    private let pageSize: Int
    /// 페이징 오프셋입니다.
    private var currentOffset = 0
    /// 다음 페이지가 있는지 여부입니다.
    private var hasMore = true
    /// 추가 페이지가 있는지 여부입니다.
    var canLoadMore: Bool { hasMore }

    /// 서비스와 쿼리를 주입받습니다.
    init(service: IGDBService, query: String, pageSize: Int = 300) {
        self.service = service
        self.query = query
        self.pageSize = pageSize
    }

    /// 단일 멀티쿼리로 게임 목록을 불러옵니다.
    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            currentOffset = 0
            hasMore = true
            let pageEntities = try await fetchPage(offset: currentOffset)
            self.entities = pageEntities
            self.items = pageEntities.map(GameListItem.init)
            hasMore = pageEntities.count == pageSize
        } catch {
            self.error = error
        }
    }

    /// 다음 페이지를 불러옵니다.
    func loadNextPage() async {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextOffset = currentOffset + pageSize
            let pageEntities = try await fetchPage(offset: nextOffset)
            currentOffset = nextOffset
            hasMore = pageEntities.count == pageSize

            self.entities.append(contentsOf: pageEntities)
            self.items = entities.map(GameListItem.init)
        } catch {
            self.error = error
        }
    }

    private func fetchPage(offset: Int) async throws -> [GameEntity] {
        let pagedQuery = queryWithPagination(offset: offset)
        let batch = [
            IGDBBatchItem(name: "list", endpoint: .games, query: pagedQuery)
        ]

        let sections = try await service.fetch(batch)
        guard let raw = sections["list"] else { return [] }

        let data = try JSONSerialization.data(withJSONObject: raw)
        let dto = try JSONDecoder().decode([IGDBGameListDTO].self, from: data)
        return dto.map(GameEntity.init)
    }

    private func queryWithPagination(offset: Int) -> String {
        // Strip any existing limit/offset to avoid duplicates.
        let stripped = query
            .replacingOccurrences(
                of: #"(?m)^\s*limit\s+\d+\s*;\s*$"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"(?m)^\s*offset\s+\d+\s*;\s*$"#,
                with: "",
                options: .regularExpression
            )

        return """
        \(stripped)
        limit \(pageSize);
        offset \(offset);
        """
    }

}
