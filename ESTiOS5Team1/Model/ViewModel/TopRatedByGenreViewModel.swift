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
    func loadPreferredGenre() async {
        let genreIds = PreferenceStore.preferredGenreIds
        let singleGenreId = PreferenceStore.preferredGenreId
        // 저장된 장르가 없으면 목록을 비웁니다.
        guard !genreIds.isEmpty || singleGenreId != nil else {
            items = []
            error = nil
            isLoading = false
            return
        }

        isLoading = true
        error = nil

        // 복수 장르 우선, 없으면 단일 장르 쿼리 사용
        let query: String
        if !genreIds.isEmpty {
            query = IGDBQuery.topRatedByGenres(genreIds)
        } else if let singleGenreId {
            query = IGDBQuery.topRatedByGenre(singleGenreId)
        } else {
            items = []
            error = nil
            isLoading = false
            return
        }

        // 쿼리별 새 VM 생성
        let vm = GameListSingleQueryViewModel(
            service: service,
            query: query
        )

        await vm.load()

        self.innerVM = vm
        self.items = vm.items
        self.error = vm.error
        self.isLoading = false
    }

    /// 외부에서 강제 갱신할 때 호출
    func refresh() async {
        await loadPreferredGenre()
    }
}
