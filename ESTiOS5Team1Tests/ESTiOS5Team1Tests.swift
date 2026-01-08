//
//  ESTiOS5Team1Tests.swift
//  ESTiOS5Team1Tests
//
//  Created by cheon on 1/6/26.
//

import XCTest
@testable import ESTiOS5Team1

/// IGDBService를 대체하기 위한 Mock 구현체입니다.
///
/// 실제 네트워크 요청 없이도
/// ViewModel의 동작을 테스트할 수 있도록
/// 성공 / 실패 결과를 직접 주입할 수 있습니다.
///
/// - Important:
/// 테스트에서는 **외부 네트워크에 의존하면 안 되므로**
/// 반드시 Mock 객체를 사용합니다.
final class MockIGDBService: IGDBService {

    /// 테스트에서 반환할 결과를 저장하는 프로퍼티
    ///
    /// 기본값은 빈 배열 성공 케이스입니다.
    var result: Result<[IGDBGameListDTO], Error> = .success([])

    /// IGDBService 프로토콜 요구사항 구현
    ///
    /// result 값에 따라 성공 또는 실패를 반환합니다.
    func fetchGameList(query: String) async throws -> [IGDBGameListDTO] {
        switch result {
            case .success(let dto):
                return dto
            case .failure(let error):
                throw error
        }
    }
}

/// ESTiOS5Team1 프로젝트의 유닛 테스트 모음입니다.
///
/// - 포함된 테스트:
///   - DTO → Entity 매핑 검증
///   - GameListViewModel의 성공 시나리오
///   - GameListViewModel의 실패 시나리오
///
/// - Note:
/// 이 테스트들은 UI가 아닌
/// **비즈니스 로직과 상태 변화를 검증**하는 것이 목적입니다.
final class ESTiOS5Team1Tests: XCTestCase {

    /// IGDBGameListDTO가 GameEntity로
    /// 올바르게 변환되는지 검증하는 테스트입니다.
    ///
    /// - 검증 항목:
    ///   - 게임 제목 매핑
    ///   - 장르 배열 변환
    ///   - 플랫폼 개수 유지
    ///   - 커버 이미지 URL 생성 여부
    func testGameEntityMapping_FromDTO() {

        // GIVEN: IGDB API에서 받아온 것과 동일한 DTO
        let dto = IGDBGameListDTO(
            id: 1,
            name: "Elden Ring",
            cover: IGDBImageDTO(imageID: "co4jni"),
            rating: 95,
            genres: [
                GenreDTO(id: 1, name: "Action"),
                GenreDTO(id: 2, name: "RPG")
            ],
            platforms: [
                IGDBPlatformDTO(id: 1, name: "PlayStation 5"),
                IGDBPlatformDTO(id: 2, name: "PC (Microsoft Windows)")
            ]
        )

        // WHEN: DTO → Entity 변환
        let entity = GameEntity(dto: dto)

        // THEN: 변환 결과 검증
        XCTAssertEqual(entity.title, "Elden Ring")
        XCTAssertEqual(entity.genre, ["Action", "RPG"])
        XCTAssertEqual(entity.platforms.count, 2)
        XCTAssertNotNil(entity.coverURL)
    }

    /// GameListViewModel이
    /// 정상적으로 데이터를 불러왔을 때의 동작을 검증합니다.
    ///
    /// - 검증 항목:
    ///   - 로딩 상태 종료 여부
    ///   - 아이템 개수
    ///   - 첫 번째 아이템 제목
    @MainActor
    func testLoadGames_Success() async {

        // GIVEN: 성공 결과를 반환하는 Mock 서비스
        let mockService = MockIGDBService()
        mockService.result = .success([
            IGDBGameListDTO(
                id: 1,
                name: "Elden Ring",
                cover: nil,
                rating: 90,
                genres: nil,
                platforms: nil
            )
        ])

        let viewModel = GameListViewModel(
            service: mockService,
            query: IGDBQuery.discover
        )

        // WHEN: 게임 목록 로드
        await viewModel.loadGames()

        // THEN: 상태 및 데이터 검증
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items.first?.title, "Elden Ring")
    }

    /// 네트워크 요청이 실패했을 때
    /// ViewModel이 오류 상태를 올바르게 처리하는지 검증합니다.
    enum TestError: Error { case failed }

    @MainActor
    func testLoadGames_Failure() async {

        // GIVEN: 실패를 반환하는 Mock 서비스
        let mockService = MockIGDBService()

        let viewModel = GameListViewModel(
            service: mockService,
            query: IGDBQuery.discover
        )

        // WHEN: 게임 목록 로드 시도
        await viewModel.loadGames()

        // THEN: 오류 상태 및 데이터 초기화 검증
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.items.isEmpty)
    }

}
