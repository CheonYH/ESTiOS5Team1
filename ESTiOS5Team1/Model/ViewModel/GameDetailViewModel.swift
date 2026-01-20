//
//  GameDetailViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation
import Combine

/// 게임 상세 데이터를 로드하고 화면 표시용 모델로 변환하는 ViewModel입니다.
@MainActor
final class GameDetailViewModel: ObservableObject {
    /// 화면에서 사용하는 상세 아이템
    @Published var item: GameDetailItem?
    /// 로딩 상태 표시
    @Published var isLoading = false
    /// 에러 상태
    @Published var error: Error?

    private let gameId: Int
    private let service: IGDBService

    init(gameId: Int, service: IGDBService? = nil) {
        self.gameId = gameId
        self.service = service ?? IGDBServiceManager()
    }

    /// 단일 게임 상세 정보를 불러옵니다.
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let dto = try await service.fetchDetail(id: gameId)
            let entity = GameDetailEntity(dto: dto)
            self.item = GameDetailItem(detail: entity)
        } catch {
            self.error = error
        }
    }
}

