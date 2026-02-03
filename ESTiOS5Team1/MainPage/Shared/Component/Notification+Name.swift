//
//  Notification+Name.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/30/26.
//

import Foundation

// MARK: - Notification Names

/// 앱 전역에서 사용하는 Notification.Name 상수를 정의합니다.
///
/// 문자열 기반 Notification을 오타 없이 재사용하기 위해 확장으로 모아 관리합니다.
extension Notification.Name {
    /// `preferredGenresDidChange` 알림 이름입니다. 관련 이벤트 발생 시 NotificationCenter를 통해 전달합니다.
    static let preferredGenresDidChange = Notification.Name("preferredGenresDidChange")
    /// `reviewDidChange` 알림 이름입니다. 관련 이벤트 발생 시 NotificationCenter를 통해 전달합니다.
    static let reviewDidChange = Notification.Name("reviewDidChange")
}
