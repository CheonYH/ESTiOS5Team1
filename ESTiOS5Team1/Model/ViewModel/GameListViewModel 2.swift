//
//  GameListViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation
import Combine

/// 게임 목록 화면의 상태와 데이터를 관리하는 ViewModel입니다.
///
/// IGDB 서비스로부터 게임 목록을 가져와
/// Entity → View 전용 모델(`GameListItem`)로 변환한 뒤
/// SwiftUI View에 상태 변화로 전달하는 역할을 담당합니다.
///
/// - Important:
/// 이 ViewModel은 `@MainActor`에서 동작하며,
/// UI 상태 변경은 항상 메인 스레드에서 안전하게 수행됩니다.
@MainActor
final class GameListViewModel: ObservableObject {

    /// 화면에 표시될 게임 목록 아이템
    ///
    /// `GameListItem`은 UI 친화적인 데이터만을 포함하며,
    /// 이 프로퍼티의 변경은 SwiftUI View를 자동으로 갱신합니다.
    @Published var items: [GameListItem] = []

    /// 데이터 로딩 중 여부
    ///
    /// 네트워크 요청 시작 시 `true`,
    /// 요청 완료 또는 실패 시 `false`로 설정됩니다.
    @Published var isLoading: Bool = false

    /// 데이터 로딩 중 발생한 오류
    ///
    /// 오류가 발생한 경우 View에서 에러 메시지를 표시하는 데 사용됩니다.
    @Published var error: Error?

    /// 게임 데이터를 가져오기 위한 서비스
    ///
    /// 프로토콜 타입으로 선언하여
    /// 테스트 및 의존성 주입이 가능하도록 설계되었습니다.
    private let service: IGDBService

    private let query: String

    /// `GameListViewModel` 초기화 메서드
    ///
    /// - Parameter service: 게임 목록을 제공하는 `IGDBService` 구현체
    init(service: IGDBService, query: String) {
        self.service = service
        self.query = query
    }

    /// IGDB로부터 게임 목록을 조회하고 화면 상태를 갱신합니다.
    ///
    /// 네트워크 요청 시작 시 로딩 상태를 활성화하고,
    /// 요청이 완료되면 결과에 따라 `items` 또는 `error`를 업데이트합니다.
    ///
    /// - Note:
    /// 이 메서드는 `async` 함수로 정의되어 있으며,
    /// 호출하는 쪽(View)에서 `await`를 통해 실행되어야 합니다.
    /// UI 상태 변경은 `@MainActor`를 통해 메인 스레드에서 안전하게 처리됩니다.
    @MainActor
    func loadGames() async {
        isLoading = true
        error = nil

        // 메서드 종료 시 항상 로딩 상태를 해제
        defer { isLoading = false }

        do {
            let dtoList = try await service.fetchGameList(query: query)

            // DTO → Entity 변환
            let entities = dtoList.map(GameEntity.init)

            // Entity → View 전용 모델 변환
            self.items = entities.map(GameListItem.init)

        } catch {
            self.error = error
        }

    }

}
