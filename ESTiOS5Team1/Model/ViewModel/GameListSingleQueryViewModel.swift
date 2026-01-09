//
//  GameListSingleQueryViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/9/26.
//

import Foundation
import Combine

final class GameListSingleQueryViewModel: ObservableObject {
    @Published var items: [GameListItem] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let service: IGDBService
    private let query: String

    init(service: IGDBService, query: String) {
        self.service = service
        self.query = query
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let batch = [
                (name: "list", endpoint: IGDBEndpoint.games, query: query)
            ]
            let sections = try await service.fetch(batch)
            if let raw = sections["list"] {
                let data = try JSONSerialization.data(withJSONObject: raw)
                let dto = try JSONDecoder().decode([IGDBGameListDTO].self, from: data)
                let entities = dto.map(GameEntity.init)
                self.items = entities.map(GameListItem.init)
            }
        } catch {
            self.error = error
        }
    }
}
