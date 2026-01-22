//
//  GameDetailViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/15/26.
//

import Foundation
import Combine

@MainActor
final class GameDetailViewModel: ObservableObject {
    @Published var item: GameDetailItem?
    @Published var isLoading = false
    @Published var error: Error?

    private let gameId: Int
    private let service: IGDBService

    init(gameId: Int, service: IGDBService = IGDBServiceManager()) {
        self.gameId = gameId
        self.service = service
    }

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
