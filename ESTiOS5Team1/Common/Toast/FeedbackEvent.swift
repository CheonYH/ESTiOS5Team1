//
//  FeedbackEvent.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/16/26.
//

import Foundation

/// 화면에 간단한 알림(Toast)을 띄울 때 사용하는 모델입니다.
///
/// ViewModel에서 작업 결과를 UI에 전달할 때 사용되며,
/// ToastManager가 이 값을 받아 실제로 화면에 표시합니다.
///
/// - Important:
///     FeedbackEvent는 **UI를 직접 제어하지 않습니다.**
///     UI와 로직을 분리하기 위해 이벤트만 전달하는 역할을 가집니다.
///
/// - Example:
///     `FeedbackEvent(source: .auth, status: .success, message: "로그인 성공!")`
struct FeedbackEvent {

    // MARK: - Feedback Source

    /// 어떤 기능에서 발생한 알림인지 표시합니다.
    ///
    /// - auth   → 로그인/회원가입
    /// - review → 리뷰 작성/삭제
    /// - rating → 별점 등록
    /// - profile → 닉네임/프로필 관련
    /// - system → 네트워크/토큰/환경 관련
    ///
    /// - Note:
    ///     Source는 나중에 Toast 위치나 스타일 정책을 결정할 때 쓸 수 있습니다.
    enum Source {
        case auth
        case review
        case rating
        case profile
        case system
    }

    // MARK: - Feedback Status

    /// 알림의 성격을 나타냅니다.
    ///
    /// - success → 작업 성공
    /// - error   → 작업 실패
    /// - warning → 입력 부족/주의 필요
    /// - info    → 단순 안내
    ///
    /// - Important:
    ///     Status는 UI 스타일(색상,진동)과 연결될 수 있습니다.
    enum Status {
        case success
        case error
        case warning
        case info
    }

    /// 실제로 화면에 표시할 메시지입니다.
    ///
    /// - Note:
    ///     사용자에게 그대로 보여지므로 개발자용 디버그 문자열을 넣으면 안 됩니다.
    let source: Source
    let status: Status
    let message: String

    // MARK: - UI Optional Properties

    /// 알림이 화면에 유지될 시간(초)입니다. 기본값은 2초입니다.
    ///
    /// - Note:
    ///     `autoDismiss = false`일 경우 duration은 사용되지 않을 수 있습니다.
    var duration: Double = 2.0

    /// 알림이 화면 어디에 표시될지 정합니다.
    ///
    /// - top    → 화면 상단
    /// - bottom → 화면 하단
    /// - auto   → 상태나 종류에 따라 자동 선택
    ///
    /// - Important:
    ///     실제 정책은 ToastManager가 결정할 수 있습니다.
    enum Placement {
        case top
        case bottom
        case auto
    }
    var placement: Placement = .auto

    /// 진동(햅틱) 효과 설정입니다.
    ///
    /// - success → 성공 진동
    /// - warning → 약한 경고 진동
    /// - error   → 실패 진동
    /// - none    → 진동 없음
    ///
    /// - Note:
    ///     지원되는 기기(iPhone)에서만 동작하며 iPad 일부 모델에서는 동작하지 않을 수 있습니다.
    enum Haptic {
        case none
        case success
        case warning
        case error
    }
    var haptic: Haptic = .none

    /// 알림이 자동으로 사라질지 여부입니다.
    ///
    /// - true  → duration 후 자동으로 사라짐
    /// - false → 사용자가 직접 닫아야 함
    ///
    /// - Use Case:
    ///     토큰 만료 → 수동 로그인 필요할 때
    var autoDismiss: Bool = true
}

extension FeedbackEvent {
    /// 편의 이니셜라이저입니다.
    ///
    /// - Parameters:
    ///   - source: 알림 발생 소스(예: `.auth`, `.review`)
    ///   - status: 알림 상태(성공/실패/경고/정보)
    ///   - message: 사용자에게 보여줄 메시지 텍스트
    ///
    /// - Default Behavior:
    ///     `duration`은 2초, `placement`는 `.auto`로 설정되며,
    ///     `haptic`은 `status`에 따라 자동 매핑됩니다.
    ///     `autoDismiss`는 기본적으로 `true`입니다.
    ///
    /// - Example:
    ///     `let event = FeedbackEvent(.auth, .success, "로그인 성공!")`
    init(_ source: Source, _ status: Status, _ message: String) {
        self.source = source
        self.status = status
        self.message = message
        self.duration = 2.0
        self.placement = .auto
        self.haptic = {
            switch status {
                case .success: return .success
                case .error: return .error
                case .warning: return .warning
                case .info: return .none
            }
        }()
        self.autoDismiss = true
    }

    /// 상태에 따라 실제 표시 위치를 해석합니다.
    ///
    /// - Returns:
    ///     `.success`, `.info` → `.bottom`
    ///     `.warning`, `.error` → `.top`
    ///
    /// - Note:
    ///     `ToastManager`는 이 값을 사용해 overlay 정렬을 결정합니다.
    var resolvedPlacement: Placement {
        switch status {
            case .success, .info:
                return .bottom
            case .warning, .error:
                return .top
        }
    }
}
