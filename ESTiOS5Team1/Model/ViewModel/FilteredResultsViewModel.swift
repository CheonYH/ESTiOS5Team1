//
//  FilteredResultsViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/20/26.
//

import Foundation
import Combine

final class FilteredResultsViewModel: ObservableObject {

    @Published var items: [GameListItem] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let service: IGDBService
    private let targetAge: GracAge

    init(targetAge: GracAge, service: IGDBService = IGDBServiceManager()) {
        self.targetAge = targetAge
        self.service = service
    }

    @MainActor
    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let batch = [
                IGDBBatchItem(
                    name: "list",
                    endpoint: .games,
                    query: IGDBQuery.filteredByAge()
                )
            ]

            let sections = try await service.fetch(batch)

            guard let raw = sections["list"] else {
                self.items = []
                return
            }

            let data = try JSONSerialization.data(withJSONObject: raw)
            let dto = try JSONDecoder().decode([IGDBGameListDTO].self, from: data)
            let entities = dto.map(GameEntity.init)

            /// GRAC 변환 후 threshold 적용
            let filtered = entities.filter {
                ($0.ageRating?.gracAge ?? .all) >= targetAge
            }

            self.items = filtered.map(GameListItem.init)

        } catch {
            self.error = error
        }
    }
}

