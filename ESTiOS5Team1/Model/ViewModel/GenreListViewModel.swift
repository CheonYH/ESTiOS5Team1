//
//  GenreListViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/8/26.
//

import Foundation
import Combine

/// IGDB로부터 장르 목록을 조회하는 ViewModel입니다.
///
/// 테스트 화면 또는 필터 화면에서 사용할 수 있으며,
/// IGDB의 `/v4/genres` 엔드포인트를 호출하여 전체 장르 목록을 불러옵니다.
///
/// - Important:
/// 이 ViewModel은 장르 정보를 받아오기만 하며,
/// 장르를 기반으로 게임을 필터링하는 기능은 다른 ViewModel에서 수행합니다.

@MainActor
final class GenreListViewModel: ObservableObject {

    /// 화면에 표시될 장르 목록
    @Published var genres: [IGDBGenreDTO] = []

    /// 로딩 상태
    @Published var isLoading = false

    /// 오류 정보 저장
    @Published var error: Error?

    /// IGDB API 요청 서비스
    private let service: IGDBService

    /// 서비스 주입 방식 초기화
    init(service: IGDBService) {
        self.service = service
    }

    /// 장르 목록을 비동기적으로 불러옵니다.
    ///
    /// - Important:
    /// `multiquery`를 사용하여 요청하며,
    /// 응답은 JSON 배열 형태로 반환되므로
    /// JSONSerialization → JSONDecoder → DTO 순으로 변환합니다.
    func loadGenres() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // IGDB multiquery 요청 구성
            let batch: [IGDBBatchItem] = [
                IGDBBatchItem(
                    name: "genres",
                    endpoint: IGDBEndpoint.genres,
                    query: "fields id, name; limit 100;"
                )
            ]

            // Service 요청 수행
            let sections = try await service.fetch(batch)

            // 응답에서 "genres" 섹션 추출
            guard let raw = sections["genres"] else { return }

            // raw(JSON Array) → Data
            let data = try JSONSerialization.data(withJSONObject: raw)

            // Data → DTO 디코딩
            let dto = try JSONDecoder().decode([IGDBGenreDTO].self, from: data)

            // UI 적용
            genres = dto

        } catch {
            self.error = error
        }
    }
}
