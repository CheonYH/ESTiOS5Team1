//
//  AgeRatingEntity.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/20/26.
//

import Foundation

/// 앱 내부에서 사용하는 연령 등급 엔티티입니다.
///
/// IGDB에서 받은 raw 등급 정보를 기반으로
/// - 기관 단위 정규화(ESRB/PEGI/GRAC 등)
/// - 한국 기준(게임물관리위원회, GRAC)으로 변환
/// - 검색/필터링이 가능한 Numeric 형태로 변환
/// 을 수행합니다.
///
/// - Note:
/// UI 표시용 텍스트는 `label`
/// 필터링/검색용 기준은 `gracAge`를 사용합니다.
struct AgeRatingEntity: Hashable {
    let system: AgeRatingSystem      // ESRB / PEGI / GRAC
    let label: String                // Teen, 16+, 청소년 이용불가 등
    let value: Int?                  // 기관 기준 numeric 값 (예: PEGI 16 → 16)
}

/// 지원하는 등급 기관 열거형
enum AgeRatingSystem: String, Hashable {
    case esrb, pegi, grac, unknown
}

/// 한국 GRAC 기준 등급 변환용 enum
///
/// - Comparable을 채택하여 필터링 연산을 지원합니다.
enum GracAge: Int, Comparable, Hashable {
    case all = 0         // 전체 이용가
    case twelve = 12     // 12세 이용가
    case fifteen = 15    // 15세 이용가
    case nineteen = 19   // 청소년 이용불가

    static func < (lhs: GracAge, rhs: GracAge) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension AgeRatingEntity {

    // MARK: - Entry Point

    /// IGDB DTO 배열을 기반으로 AgeRatingEntity를 생성합니다.
    ///
    /// - Important:
    /// ESRB > PEGI > GRAC 순으로 우선 적용합니다.
    nonisolated static func from(_ dto: [IGDBAgeRatingDTO]?) -> AgeRatingEntity? {
        guard let dto, !dto.isEmpty else { return nil }

        // ESRB 우선
        if let esrb = dto.first(where: { $0.category == 1 }) {
            return .init(
                system: .esrb,
                label: mapESRBLabel(code: esrb.rating),
                value: mapESRBValue(code: esrb.rating)
            )
        }

        // PEGI 다음
        if let pegi = dto.first(where: { $0.category == 2 }) {
            return .init(
                system: .pegi,
                label: mapPEGILabel(code: pegi.rating),
                value: mapPEGIValue(code: pegi.rating)
            )
        }

        // GRAC 직접 있는 경우 (드문 편)
        if let grac = dto.first(where: { $0.category == 5 }) {
            return .init(
                system: .grac,
                label: mapGRACLabel(code: grac.rating),
                value: mapGRACValue(code: grac.rating)
            )
        }

        // 기타 기관은 Unknown
        return .init(system: .unknown, label: "Unknown", value: nil)
    }

    // MARK: - ESRB Mapping

    nonisolated private static func mapESRBLabel(code: Int) -> String {
        switch code {
            case 1: return "EC"
            case 2: return "E"
            case 3: return "E10+"
            case 4: return "Teen"
            case 5: return "Mature"
            case 6: return "Adults Only"
            default: return "Unknown"
        }
    }

    nonisolated private static func mapESRBValue(code: Int) -> Int? {
        switch code {
            case 1: return 3
            case 2: return 6
            case 3: return 10
            case 4: return 13
            case 5: return 17
            case 6: return 18
            default: return nil
        }
    }

    // MARK: - PEGI Mapping

    nonisolated private static func mapPEGILabel(code: Int) -> String {
        switch code {
            case 7: return "3+"
            case 8: return "7+"
            case 9: return "12+"
            case 10: return "16+"
            case 11: return "18+"
            default: return "Unknown"
        }
    }

    nonisolated private static func mapPEGIValue(code: Int) -> Int? {
        switch code {
            case 7: return 3
            case 8: return 7
            case 9: return 12
            case 10: return 16
            case 11: return 18
            default: return nil
        }
    }

    // MARK: - GRAC Direct Mapping

    nonisolated private static func mapGRACLabel(code: Int) -> String {
        switch code {
            case 0: return "전체 이용가"
            case 12: return "12세 이용가"
            case 15: return "15세 이용가"
            case 19: return "청소년 이용불가"
            default: return "등급 정보 없음"
        }
    }

    nonisolated private static func mapGRACValue(code: Int) -> Int? {
        switch code {
            case 0: return 0
            case 12: return 12
            case 15: return 15
            case 19: return 19
            default: return nil
        }
    }

    // MARK: - 한국 GRAC 기준 변환

    /// 한국 게임물관리위원회(GRAC) 기준으로 변환합니다.
    ///
    /// 검색/필터링 시 다음처럼 사용할 수 있습니다:
    ///
    ///     games.filter { $0.ageRating?.gracAge ?? .all >= .fifteen }
    ///
    var gracAge: GracAge {
        switch system {

            case .grac:
                if let value {
                    switch value {
                        case 0:  return .all
                        case 12: return .twelve
                        case 15: return .fifteen
                        case 19: return .nineteen
                        default: return .all
                    }
                }
                return .all

            case .esrb:
                if let value {
                    switch value {
                        case ..<10: return .all
                        case 10...13: return .twelve
                        case 14...16: return .fifteen
                        case 17...: return .nineteen
                        default: return .all
                    }
                }
                return .all

            case .pegi:
                if let value {
                    switch value {
                        case 3, 7: return .all
                        case 12: return .twelve
                        case 16: return .fifteen
                        case 18: return .nineteen
                        default: return .all
                    }
                }
                return .all

            default:
                return .all
        }
    }
}
