//
//  PlatformTestViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/9/26.
//

import Foundation
import Combine

/// IGDB로부터 플랫폼 목록을 조회하는 ViewModel입니다.
///
/// 테스트 목적의 View에서 사용되며,
/// IGDB의 `/v4/platforms` 엔드포인트를 호출하여
/// 전체 플랫폼 목록을 불러온 뒤 SwiftUI에 반영합니다.
///
/// - Important:
/// 이 ViewModel은 데이터 가공을 거의 하지 않으며,
/// 응답을 그대로 DTO로 디코딩해 전달합니다.
/// UI에서 필터링/정렬/매핑 등이 필요해지면
/// 이후 단계에서 확장할 수 있습니다.
@MainActor
final class PlatformTestViewModel: ObservableObject {

    /// 화면에 표시할 플랫폼 목록
    ///
    /// `IGDBPlatformDTO`는 원본 API 데이터를 그대로 표현하는 DTO입니다.
    @Published var platforms: [IGDBPlatformDTO] = []

    /// 로딩 상태 관리
    @Published var isLoading = false

    /// 에러 상태 저장
    @Published var error: Error?

    /// IGDB API 호출 서비스
    ///
    /// 프로토콜 타입으로 선언하여 테스트 가능성을 높입니다.
    private let service: IGDBService

    /// 초기화 시 서비스 주입
    init(service: IGDBService) {
        self.service = service
    }

    /// 플랫폼 목록을 비동기로 로드합니다.
    ///
    /// - Important:
    /// multiquery 요청을 사용하여 효율적으로 데이터를 받아오며,
    /// 응답은 JSON 배열 형태로 전달되므로
    /// JSONSerialization → JSONDecoder → DTO 순으로 변환합니다.
    ///
    /// - Endpoint:
    ///   `POST /v4/multiquery` (`platforms` 블록)
    ///
    /// - Returns:
    ///   없음 (내부 상태 `platforms` 갱신)
    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // IGDB multiquery 요청 블록 정의
            let batch: [IGDBBatchItem] = [
                IGDBBatchItem(
                    name: "platforms",
                    endpoint: IGDBEndpoint.platforms,
                    query: IGDBQuery.allPlatforms
                )
            ]

            // multiquery 실행
            let sections = try await service.fetch(batch)

            // 응답에서 "platforms" 섹션 추출
            guard let raw = sections["platforms"] else { return }

            // JSONSerialization → Data
            let data = try JSONSerialization.data(withJSONObject: raw)

            // Data → DTO 배열
            let dto = try JSONDecoder().decode([IGDBPlatformDTO].self, from: data)

            // UI 반영
            platforms = dto

        } catch {
            self.error = error
        }
    }
}
