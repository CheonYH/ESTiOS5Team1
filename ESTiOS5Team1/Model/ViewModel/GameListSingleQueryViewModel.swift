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
final class GameListSingleQueryViewModel: ObservableObject {

    /// 화면에 표시될 게임 목록
    @Published var items: [GameListItem] = []

    /// 네트워크 로딩 상태
    @Published var isLoading = false

    /// 오류 정보 저장
    @Published var error: Error?

    /// Discover 화면에서 선택된 연령 필터
    ///
    /// - Default: `.all` (전체 보기)
    ///
    /// - Note:
    /// didSet에서 `applyFilter()`를 호출하여 UI에 즉시 반영합니다.
    @Published var selectedAge: GracAge = .all {
        didSet { applyFilter() }
    }

    /// 네트워크로 받아온 원본 Entity 목록 저장소
    ///
    /// - Important:
    /// 필터링/정렬 시 원본 보존이 필요하기 때문에
    /// 화면 표시용(items)와 분리되어 있습니다.
    private var entities: [GameEntity] = []

    private let service: IGDBService
    private let query: String

    /// Service 및 Query 기반 초기화
    ///
    /// - Parameter query:
    ///   IGDB MultiQuery에서 사용할 raw query 문자열
    init(service: IGDBService, query: String) {
        self.service = service
        self.query = query
    }

    /// 게임 목록 로드
    ///
    /// - Important:
    ///   MultiQuery(`batch`) → JSON 디코딩 → DTO → Entity → ViewModel 순으로 가공됩니다.
    @MainActor
    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // IGDB multiquery 구성
            let batch: [IGDBBatchItem] = [
                IGDBBatchItem(
                    name: "list",
                    endpoint: IGDBEndpoint.games,
                    query: query
                )
            ]

            // Service 요청 수행
            let sections = try await service.fetch(batch)

            // "list" 섹션 추출
            if let raw = sections["list"] {

                // raw(JSON Array) → Data 변환
                let data = try JSONSerialization.data(withJSONObject: raw)

                // Data → DTO 디코딩
                let dto = try JSONDecoder().decode([IGDBGameListDTO].self, from: data)

                // DTO → Domain Entity
                self.entities = dto.map(GameEntity.init)

                // 연령정보 있는 게임 우선 정렬
                self.entities.sort {
                    ($0.ageRating != nil) && ($1.ageRating == nil)
                }

                // 필터 적용
                applyFilter()

            }

            print("Total:", entities.count)
            print("With Age:", entities.filter { $0.ageRating != nil }.count)

        } catch {
            self.error = error
        }
    }

    /// Discover 화면에서 선택한 연령 기준으로 필터링합니다.
    ///
    /// - Important:
    ///   `GameEntity.ageRating?.gracAge` 기준으로 비교하며,
    ///   값을 갖지 않는 경우 `.all`로 간주합니다.
    ///
    /// - Example:
    ///     `.fifteen` 선택 시 → 15세 이상 + 청소년 이용불가
    ///
    func applyFilter() {
        switch selectedAge {
        case .all:
            self.items = entities.map(GameListItem.init)

        default:
            // 연령 있는 게임 + 조건 만족하는 애들 먼저
            let priority = entities.filter {
                guard let age = $0.ageRating?.gracAge else { return false }
                return age >= selectedAge
            }

            // 연령 정보 없는 애들은 뒤로
            let fallback = entities.filter {
                $0.ageRating == nil
            }

            self.items = (priority + fallback).map(GameListItem.init)
        }
    }

}
