//
//  ToastModel.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import Foundation
import SwiftUI

// MARK: - ToastMessage

/// 화면에 간단한 알림(Toast)을 표시하기 위한 데이터 모델입니다.
///
/// - Purpose:
///     ToastMessage는 UI에서 바로 렌더링하기 위한 정보를 담습니다.
///     FeedbackEvent보다 UI 친화적인 형태입니다.
///
/// - Important:
///     이 모델은 화면에서 텍스트/아이콘/색상을 결정하는 데 사용됩니다.
///     비즈니스 로직은 `FeedbackEvent`에서 처리하고,
///     UI는 `ToastMessage`를 사용하여 그립니다.
///
/// - Example:
///     `ToastMessage(text: "로그인 성공!", type: .success)`

struct ToastMessage: Identifiable {
    /// 각 메시지를 식별하기 위한 고유 ID입니다.
    ///
    /// - Important:
    ///     리스트 렌더링 및 애니메이션에서 안정적인 식별을 위해 사용됩니다.
    let id = UUID()

    /// 사용자에게 보여줄 텍스트입니다.
    ///
    /// - Example:
    ///     "리뷰가 등록되었습니다."
    let text: String

    /// 메시지의 상태(성공/실패/경고/정보)를 나타냅니다.
    ///
    /// - Note:
    ///     이 값은 색상과 아이콘을 결정할 때 사용됩니다.
    let type: ToastType
}

// MARK: - ToastContext
/// Toast가 어떤 기능 영역에서 발생했는지 구분하기 위한 Context입니다.
///
/// - Use Case:
///     나중에 토스트 위치나 정책을 기능별로 다르게 적용할 수 있습니다.
///
/// - Example:
///     `.auth` → 로그인/회원가입
///     `.review` → 리뷰 작성/삭제
///     `.rating` → 별점 등록
///     `.system` → 네트워크/토큰 문제
enum ToastContext {
    case auth
    case review
    case profile
    case rating
    case system
}

// MARK: - ToastType
/// Toast 스타일(상태)을 나타냅니다.
///
/// - success → 작업 성공 (예: 리뷰 등록 완료)
/// - error   → 작업 실패 (예: 로그인 실패)
/// - warning → 입력 부족 등 주의 필요
/// - info    → 단순 안내 (예: 로그아웃됨)
///
/// - Important:
///     이 값은 UI 색상, 아이콘, 햅틱 등의 UX 요소와 연결됩니다.
enum ToastType {
    case success
    case error
    case warning
    case info
}

extension ToastType {
    // MARK: - UI Helpers

    /// 상태별 배경 색상 설정
    ///
    /// - Returns:
    ///   토스트 상태에 맞는 반투명 배경 색상
    var color: Color {
        switch self {
        case .success: .green.opacity(0.85)
        case .error: .red.opacity(0.85)
        case .warning: .yellow.opacity(0.85)
        case .info: .blue.opacity(0.85)
        }
    }

    /// 상태별 SF Symbol 아이콘 설정
    ///
    /// - Example:
    ///     Image(systemName: ToastType.success.icon)
    ///
    /// - Important:
    ///     `.circle.fill`은 토스트처럼 작은 컴포넌트에서 잘 보이며,
    ///     `.triangle.fill`은 주의/경고의 시각적 표현으로 적합합니다.
    ///
    /// - Returns:
    ///   상태별 SF Symbol 이름 문자열
    var icon: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .error: "exclamationmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
    }
}
