//
//  ToastManager.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/17/26.
//

import SwiftUI
import Combine

/// Toast UI 표시를 관리하는 객체입니다.
///
/// - Purpose:
///     ViewModel 또는 도메인 계층에서 생성한 `FeedbackEvent`를 UI에서 표시할 수 있도록 연결해주는 역할을 합니다.
///
/// - Architecture Role:
///     `ViewModel → FeedbackEvent → ToastManager → ToastView` 흐름을 통해
///     비즈니스 로직과 UI 로직의 의존성을 분리합니다.
///
/// - Important:
///     ToastManager는 직접 UI를 만들지 않습니다.
///     상태(`event`, `placement`)만 관리하고 UI는 SwiftUI View가 결정합니다.
///
/// - Note:
///     이 패턴은 실무에서도 많이 사용하는 Event-Driven UI 패턴입니다.
@MainActor
final class ToastManager: ObservableObject {

    // MARK: - Published Properties

    /// 현재 표시할 Toast 이벤트입니다.
    /// nil이면 토스트가 사라진 상태를 의미합니다.
    @Published var event: FeedbackEvent?

    /// Toast가 화면 어디에 표시될지(top/bottom)를 저장합니다.
    /// - Important:
    ///     위치는 `FeedbackEvent`의 정책에 따라 자동으로 결정됩니다.
    @Published var placement: FeedbackEvent.Placement = .auto


    // MARK: - Public API

    /// Toast를 화면에 표시합니다.
    ///
    /// - Parameter event: 표시할 `FeedbackEvent`
    ///
    /// - Important:
    ///     보여지는 시간(duration), 진동(haptic), 닫힘 정책(autoDismiss)은 모두 `event`에 정의된 값을 따릅니다.
    ///
    /// - Note:
    ///     `placement`는 `event.resolvedPlacement`에 따라 자동으로 갱신됩니다.
    ///
    /// - Example:
    ///     `toastManager.show(FeedbackEvent(.auth, .success, "로그인 성공!"))`
    func show(_ event: FeedbackEvent) {
        // UI에 표시할 이벤트 설정
        withAnimation(.spring()) {
            self.event = event
            self.placement = event.resolvedPlacement
        }

        // 기기가 지원하는 경우 햅틱 실행
        applyHaptic(event.haptic)

        // 자동으로 닫히는 이벤트 처리
        if event.autoDismiss {
            Task {
                try? await Task.sleep(for: .seconds(event.duration))
                dismiss()
            }
        }
    }

    /// Toast를 수동으로 닫습니다.
    ///
    /// - Use Case:
    ///     세션 만료, 재로그인 필요 같은 경우처럼 사용자가 직접 확인해야 하는 상황에서 사용합니다.
    ///
    /// - Example:
    ///     ```swift
    ///     toastManager.dismiss()
    ///     ```
    func dismiss() {
        withAnimation(.spring()) {
            self.event = nil
        }
    }


    // MARK: - Private Helpers

    /// 기기에서 햅틱(진동) 효과를 실행합니다.
    ///
    /// - Parameter haptic: 실행할 햅틱 효과 타입
    ///
    /// - Important:
    ///     iOS 기기에서만 동작합니다. iPad 일부 모델과 시뮬레이터에서는 무시될 수 있습니다.
    ///
    /// - Note:
    ///     내부적으로 `UIImpactFeedbackGenerator` 및 `UINotificationFeedbackGenerator`를 사용합니다.
    private func applyHaptic(_ haptic: FeedbackEvent.Haptic) {
        #if os(iOS)
        switch haptic {
        case .success:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .warning:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .none:
            break
        }
        #endif
    }
}

