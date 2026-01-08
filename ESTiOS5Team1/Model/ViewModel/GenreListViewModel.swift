//
//  GenreListViewModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/8/26.
//

import Foundation
import Combine

/// 장르 목록 화면의 상태와 데이터를 관리하는 ViewModel입니다.
///
/// IGDB API로부터 장르 목록을 가져와
/// SwiftUI View에 전달하는 역할을 담당합니다.
///
/// - Note:
/// 장르 목록은 항상 동일한 요청을 사용하므로,
/// 쿼리는 ViewModel 내부에서 고정되어 있습니다.
@MainActor
final class GenreListViewModel: ObservableObject {

    /// 화면에 표시될 장르 목록
    @Published var genres: [IGDBGenreDTO] = []

    /// 데이터 로딩 중 여부
    @Published var isLoading = false

    /// 로딩 중 발생한 에러 정보
    @Published var error: Error?

    /// IGDB API와 통신하기 위한 서비스
    ///
    /// 프로토콜 타입으로 선언하여
    /// 테스트 및 구현 교체가 가능하도록 합니다.
    private let service: IGDBService

    /// `GenreListViewModel` 초기화 메서드
    ///
    /// - Parameter service: IGDB API 통신을 담당하는 서비스
    init(service: IGDBService) {
        self.service = service
    }

    /// IGDB로부터 장르 목록을 조회합니다.
    ///
    /// 네트워크 요청 중에는 로딩 상태를 활성화하고,
    /// 요청이 완료되면 장르 목록 또는 에러 상태를 갱신합니다.
    func loadGenres() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let query = "fields id, name; limit 100;"
            self.genres = try await service.fetchGenres(query: query)
        } catch {
            self.error = error
        }
    }
}
