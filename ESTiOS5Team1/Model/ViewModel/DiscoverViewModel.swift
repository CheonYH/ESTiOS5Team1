//
//  DiscoverViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation
import Combine

/// 홈 화면(Discover)에서 사용되는 게임 목록 데이터를 관리하는 ViewModel입니다.
///
/// IGDB API에 여러 종류의 게임 목록을 한 번에 요청(multi-query)한 뒤
/// 화면에서 사용할 수 있는 모델(`GameListItem`)로 변환하여 제공합니다.
///
/// - Important:
/// UI 업데이트는 항상 메인 스레드에서 안전하게 수행하기 위해
/// 이 ViewModel 전체가 `@MainActor`에서 실행됩니다.
/// 그러나 데이터 디코딩 및 매핑 처리와 같은 CPU 비용이 큰 작업은
/// 백그라운드로 분리하여 화면 성능 저하를 방지합니다.
@MainActor
final class DiscoverViewModel: ObservableObject {

    /// 홈 화면의 인기 게임 섹션에 표시될 데이터
    @Published var trendingItems: [GameListItem] = []

    /// 홈 화면의 추천 게임 섹션에 표시될 데이터
    @Published var discoverItems: [GameListItem] = []

    /// 로딩 상태 표시 (스피너 등)
    @Published var isLoading: Bool = false

    /// 오류 발생 시 View에서 메시지를 표현하기 위한 상태
    @Published var error: Error?

    /// IGDB API와 통신하는 서비스
    private let service: IGDBService

    private let reviewService: ReviewService

    // MARK: - Init

    init(service: IGDBService, reviewService: ReviewService? = nil) {
        self.service = service
        self.reviewService = reviewService ?? ReviewServiceManager()
    }

    // MARK: - Public API

    /// 홈 화면에 필요한 게임 목록을 불러옵니다.
    ///
    /// - Important:
    /// multi-query 요청으로 여러 섹션을 한 번에 조회하며,
    /// 디코딩 및 데이터 매핑은 백그라운드에서 처리하여
    /// UI 프레임 드랍을 방지합니다.
    ///
    /// - Note:
    /// View에서는 `await viewModel.load()` 형태로 호출합니다.
    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // multi-query 구성
            // 각 요소는 화면의 "섹션"에 대응합니다.
            let batch: [IGDBBatchItem] = [
                .init(name: "trending", endpoint: IGDBEndpoint.games, query: IGDBQuery.trendingNow),
                .init(name: "discover", endpoint: IGDBEndpoint.games, query: IGDBQuery.discover)
            ]

            // IGDB API 요청
            let sections = try await service.fetch(batch)

            // MARK: - 디코딩 및 매핑 (백그라운드 처리)

            let (trendingEntities, discoverEntities) = try await Task(priority: .userInitiated) {

                func decodeEntities(_ raw: [[String: Any]]?) throws -> [GameEntity] {
                    guard let raw else { return [] }
                    let data = try JSONSerialization.data(withJSONObject: raw)
                    let dto = try JSONDecoder().decode([IGDBGameListDTO].self, from: data)
                    return dto.map(GameEntity.init)
                }

                let trendingEntities = try decodeEntities(sections["trending"])
                let discoverEntities = try decodeEntities(sections["discover"])

                return (trendingEntities, discoverEntities)

            }.value

            let trendingStatsById = await fetchStatsMap(for: trendingEntities)
            let discoverStatsById = await fetchStatsMap(for: discoverEntities)
            let emptyReview = GameReviewEntity(reviews: [], stats: nil, myReview: nil)

            // MARK: - UI 업데이트 (메인스레드)

            await MainActor.run {
                self.trendingItems = trendingEntities.map {
                    GameListItem(entity: $0, review: trendingStatsById[$0.id] ?? emptyReview)
                }
                self.discoverItems = discoverEntities.map {
                    GameListItem(entity: $0, review: discoverStatsById[$0.id] ?? emptyReview)
                }
            }

        } catch {
            self.error = error
        }
    }

    private func fetchStatsMap(for entities: [GameEntity]) async -> [Int: GameReviewEntity] {
        let ids = entities.map { $0.id }
        guard !ids.isEmpty else { return [:] }

        let maxConcurrent = 10
        var results: [Int: GameReviewEntity] = [:]

        await withTaskGroup(of: (Int, GameReviewEntity?).self) { group in
            var iterator = ids.makeIterator()

            func addNext() {
                guard let id = iterator.next() else { return }
                group.addTask {
                    do {
                        let stats = try await self.reviewService.stats(gameId: id)
                        let review = await GameReviewEntity(reviews: [], stats: stats, myReview: nil)
                        return (id, review)
                    } catch {
                        return (id, nil)
                    }
                }
            }

            for _ in 0..<maxConcurrent { addNext() }

            while let (id, review) = await group.next() {
                if let review { results[id] = review }
                addNext()
            }
        }

        return results
    }
}
