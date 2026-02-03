//
//  File.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/29/26.
//

import Foundation
import Combine

/// 선호 장르(복수) 기반으로 메타크리틱 상위 게임을 로드하는 ViewModel
@MainActor
final class TopRatedByGenreViewModel: ObservableObject {
    /// 화면에 표시할 게임 목록
    @Published var items: [GameListItem] = []
    /// 로딩 상태
    @Published var isLoading: Bool = false
    /// 에러 상태
    @Published var error: Error?

    /// IGDB API 서비스
    private let service: IGDBService
    /// 내부 로딩용 VM (쿼리 기반)
    private var innerVM: GameListSingleQueryViewModel?

    /// 서비스 주입 (기본값: IGDBServiceManager)
    init(service: IGDBService? = nil) {
        self.service = service ?? IGDBServiceManager()
    }

    /// UserDefaults에 저장된 선호 장르 기준으로 목록을 로드합니다.
    ///
    /// - Endpoint:
    ///   내부적으로 장르별 `POST /v4/multiquery`를 호출합니다.
    ///
    /// - Parameters:
    ///   - showLoading: 기존 목록이 있을 때 로딩 UI 표시 여부
    ///
    /// - Returns:
    ///   없음 (내부 상태 `items` 갱신)
    func loadPreferredGenre(showLoading: Bool = true) async {
        let genreIds = PreferenceStore.preferredGenreIds
        let singleGenreId = PreferenceStore.preferredGenreId
        // 저장된 장르가 없으면 목록을 비웁니다.
        guard !genreIds.isEmpty || singleGenreId != nil else {
            items = []
            error = nil
            isLoading = false
            return
        }

        // 이미 목록이 있으면 새 데이터가 올 때까지 화면을 유지합니다.
        isLoading = showLoading && items.isEmpty
        error = nil

        // 복수 장르: 장르별 5개씩 조회 후 합산
        if !genreIds.isEmpty {
            var combined: [GameListItem] = []
            var lastError: Error?

            for genreId in genreIds {
                let vm = GameListSingleQueryViewModel(
                    service: service,
                    query: IGDBQuery.topRatedByGenre(genreId),
                    pageSize: 5
                )
                await vm.load()
                combined.append(contentsOf: vm.items)
                if let err = vm.error { lastError = err }
            }

            let sorted = combined.sorted {
                let lhs = Double($0.ratingText.replacingOccurrences(of: "/5", with: "")) ?? 0
                let rhs = Double($1.ratingText.replacingOccurrences(of: "/5", with: "")) ?? 0
                return lhs > rhs
            }

            var seen = Set<Int>()

            self.innerVM = nil
            self.items = sorted.filter { seen.insert($0.id).inserted }
            self.error = lastError
            self.isLoading = false
            return
        }

        // 단일 장르: 상위 5개만 조회
        if let singleGenreId {
            let vm = GameListSingleQueryViewModel(
                service: service,
                query: IGDBQuery.topRatedByGenre(singleGenreId),
                pageSize: 5
            )

            await vm.load()

            self.innerVM = vm
            self.items = vm.items
            self.error = vm.error
            self.isLoading = false
            return
        }

        items = []
        error = nil
        isLoading = false
    }

    /// 외부에서 강제 갱신할 때 호출
    ///
    /// - Endpoint:
    ///   `loadPreferredGenre(showLoading: false)` 위임
    ///
    /// - Returns:
    ///   없음
    func refresh() async {
        await loadPreferredGenre(showLoading: false)
    }
}
