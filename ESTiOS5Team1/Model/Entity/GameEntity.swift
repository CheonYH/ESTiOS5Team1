import Foundation
import Combine

/// 앱 내부에서 사용하는 게임 모델입니다.
///
/// IGDB API에서 받아온 데이터를
/// 앱에서 사용하기 편한 형태로 변환해 저장합니다.
///
/// - Important:
/// 이 타입은 UI 표시나 네트워크 요청에 직접 사용되지 않고,
/// 앱 내부에서 게임 데이터를 공통으로 관리하기 위한 모델입니다.
struct GameEntity: Identifiable, Hashable {

    /// 게임 ID (IGDB에서 제공)
    let id: Int

    /// 게임 제목
    let title: String

    /// 게임 커버 이미지 URL
    ///
    /// 커버 이미지가 없는 경우 `nil`일 수 있습니다.
    let coverURL: URL?

    /// 게임 평점 (0 ~ 100)
    ///
    /// 화면에 표시할 때는 View 쪽에서
    /// 5점 만점 등으로 가공해서 사용합니다.
    let rating: Double?

    /// 게임 장르 목록
    ///
    /// 장르 정보가 없는 경우에도
    /// 앱에서는 항상 빈 배열로 처리합니다.
    let genre: [String]

    /// 게임이 지원하는 플랫폼 목록
    ///
    /// IGDB의 플랫폼 이름을
    /// 앱에서 사용하는 플랫폼 모델로 변환한 결과입니다.
    let platforms: [GamePlatform]

    /// 출시 연도입니다. (없을 수 있음)
    let releaseYear: Int?

    /// 게임 요약 텍스트입니다.
    let summary: String?

}

extension GameEntity {

    /// IGDB API 응답(DTO)을 기반으로 `GameEntity`를 생성합니다.
    ///
    /// 이 초기화 메서드는 다음 작업을 수행합니다.
    /// - Optional 값 처리
    /// - 커버 이미지 URL 생성
    /// - 장르 목록 기본값 처리
    /// - 플랫폼 DTO → 앱 내부 플랫폼 모델 변환
    ///
    /// - Parameter dto: IGDB에서 받아온 게임 데이터
    nonisolated init(gameListDTO: IGDBGameListDTO) {
        self.id = gameListDTO.id
        self.title = gameListDTO.name

        // 커버 이미지 URL 생성
        if let imageID = gameListDTO.cover?.imageID {
            // 목록 화면은 중간 사이즈로 로딩 비용을 줄입니다.
            self.coverURL = makeIGDBImageURL(imageID: imageID, size: .coverMed)
        } else {
            self.coverURL = nil
        }

        // 검색/목록 평점은 리뷰 통계 기준으로 사용하므로 원본 평점은 보관하지 않습니다.
        self.rating = nil

        // 장르 처리
        self.genre = gameListDTO.genres?.map { $0.name } ?? []

        // 플랫폼 매핑
        self.platforms = gameListDTO.platforms?.map {
            GamePlatform(name: $0.name)
        } ?? []

        // 요약/설명
        self.summary = gameListDTO.summary

        // 출시년도 (최신 값 기준)
        if let years = gameListDTO.releaseDates?.compactMap({ $0.year }), let latestYear = years.max() {
            self.releaseYear = latestYear
        } else {
            self.releaseYear = nil
        }

    }
}
