//
//  TabBarState.swift
//  ESTiOS5Team1
//
//  Created by JaeYeongMAC on 1/26/26.
//

import SwiftUI
import Combine

// MARK: - TabBarState

/// 커스텀 탭바의 표시/숨김 상태를 관리하는 ObservableObject 입니다.
///
/// 화면 전환(예: 상세 화면 push) 시 탭바를 숨기거나 다시 나타낼 때 사용합니다.
final class TabBarState: ObservableObject {
    
    /// 탭바 숨김 여부
    ///
    /// - Note:
    ///   `true`면 탭바를 숨기고, `false`면 탭바를 표시합니다.
    @Published var isHidden: Bool = false
}
