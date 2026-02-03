//
//  PaddingValue.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/15/26.
//

import Foundation

/// 프로젝트 전반에서 사용하는 간격(Spacing) 상수를 모아둔 네임스페이스입니다.
///
/// - Note:
///   디자인 토큰처럼 공통 간격 값을 한 곳에서 관리하면
///   화면별로 제각각 값이 퍼지는 것을 방지할 수 있습니다.
///
/// - Example:
///   `padding(Spacing.pv10)`
enum Spacing {
    /// 기본 패딩/간격 10pt
    static let pv10: CGFloat = 10
    /// 작은 간격(또는 기본 코너 값) 8pt
    static let cr: CGFloat = 8
}
/// ex) padding(Spacing.pv10) << 사용

/// 프로젝트 전반에서 사용하는 모서리 반경(Radius) 상수를 모아둔 네임스페이스입니다.
///
/// - Note:
///   RoundedRectangle/clipShape/cornerRadius 등에 동일한 값을 재사용해
///   UI 일관성을 유지합니다.
///
/// - Example:
///   `cornerRadius(Radius.cr8)`
///   `RoundedRectangle(cornerRadius: Radius.card)`
enum Radius {
    /// 코너 반경 8pt
    static let cr8: CGFloat = 8
    /// 코너 반경 12pt
    static let cr12: CGFloat = 12
    /// 코너 반경 16pt
    static let cr16: CGFloat = 16
    /// 카드 UI 기본 코너 반경 20pt
    static let card: CGFloat = 20
}
/// ex) Radius.cr8 << 사용
