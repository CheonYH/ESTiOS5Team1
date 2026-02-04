import Foundation

/// 검색 화면 전용 게임 데이터 서비스입니다.
///
/// IGDB 게임 목록과 리뷰 통계를 결합해 `GameListItem`을 생성합니다.
///
/// - Responsibilities:
///     - IGDB 게임 목록 조회
///     - 게임별 리뷰 통계 조회
///     - DTO/Entity를 화면 모델(`GameListItem`)로 변환
final class SearchGameDataService: GameDataServiceProtocol {
    /// IGDB 게임 데이터 조회 서비스입니다.
    private let igdbService: IGDBService
    /// 리뷰 통계 조회 서비스입니다.
    private let reviewService: ReviewService

    /// 검색 데이터 서비스 인스턴스를 생성합니다.
    ///
    /// - Parameters:
    ///   - igdbService: IGDB 조회 서비스
    ///   - reviewService: 리뷰 조회 서비스
    init(
        igdbService: IGDBService = IGDBServiceManager(),
        reviewService: ReviewService = ReviewServiceManager()
    ) {
        self.igdbService = igdbService
        self.reviewService = reviewService
    }

    /// 게임 목록을 조회하고 리뷰 통계를 결합해 반환합니다.
    ///
    /// - Endpoint:
    ///   - IGDB: `POST /v4/multiquery`
    ///   - Review: `GET /reviews/game/{gameId}/stats`
    ///
    /// - Parameters:
    ///   - query: IGDB 쿼리 문자열
    ///   - offset: 페이지네이션 시작 위치
    ///   - limit: 한 번에 가져올 게임 수
    ///
    /// - Returns:
    ///   리뷰 통계가 결합된 `GameListItem` 배열
    ///
    /// - Throws:
    ///   네트워크 오류 / 서버 응답 오류 / 디코딩 오류
    func fetchGames(query: String, offset: Int, limit: Int) async throws -> [GameListItem] {
        // 기존 쿼리에 남아 있는 limit/offset을 제거해 중복 선언을 방지합니다.
        let strippedQuery = query
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

        // 현재 페이지 기준으로 limit/offset을 다시 주입합니다.
        let pagedQuery = """
        \(strippedQuery)
        limit \(limit);
        offset \(offset);
        """

        let batch = [
            IGDBBatchItem(name: "searchList", endpoint: .games, query: pagedQuery)
        ]

        let sections = try await igdbService.fetch(batch)
        guard let raw = sections["searchList"] else { return [] }

        // IGDB 응답을 DTO -> Entity로 변환합니다.
        let data = try JSONSerialization.data(withJSONObject: raw)
        let dtos = try JSONDecoder().decode([IGDBGameListDTO].self, from: data)
        let entities = dtos.map(GameEntity.init)

        // 게임 ID 기준으로 리뷰 통계를 병렬 조회합니다.
        let reviewStatsByID = await fetchReviewStatsMap(ids: entities.map(\.id))

        // 화면 모델 생성은 MainActor에서 수행합니다.
        return await MainActor.run {
            entities.map { entity in
                let review = GameReviewEntity(
                    reviews: [],
                    stats: reviewStatsByID[entity.id],
                    myReview: nil
                )
                return GameListItem(entity: entity, review: review)
            }
        }
    }
}

private extension SearchGameDataService {
    /// 검색/목록 아이템에 사용할 리뷰 통계를 병렬 조회합니다.
    ///
    /// - Parameters:
    ///   - ids: 리뷰 통계를 조회할 게임 ID 배열
    ///
    /// - Returns:
    ///   `gameId -> ReviewStatsResponse` 매핑 딕셔너리
    func fetchReviewStatsMap(ids: [Int]) async -> [Int: ReviewStatsResponse] {
        guard !ids.isEmpty else { return [:] }

        let maxConcurrent = 10
        var results: [Int: ReviewStatsResponse] = [:]

        await withTaskGroup(of: (Int, ReviewStatsResponse?).self) { group in
            var iterator = ids.makeIterator()

            func addNext() {
                guard let id = iterator.next() else { return }
                group.addTask {
                    do {
                        let stats = try await self.reviewService.stats(gameId: id)
                        return (id, stats)
                    } catch {
                        return (id, nil)
                    }
                }
            }

            for _ in 0..<maxConcurrent { addNext() }

            while let (id, stats) = await group.next() {
                if let stats { results[id] = stats }
                addNext()
            }
        }

        return results
    }
}
