//
//  ProfileStyle.swift
//  ESTiOS5Team1
//
//  Created by Codex on 1/30/26.
//

import SwiftUI

/// 프로필 화면 전용 레이아웃/타이포그래피 토큰입니다.
///
/// 기기 크기(regular/compact)에 따라 아바타, 버튼, 폰트 스케일을
/// 한 번에 제어하기 위해 사용합니다.
struct ProfileStyle {
    /// 프로필 아이콘 실제 크기입니다.
    let avatarSize: CGFloat
    /// 프로필 아이콘 외곽 패딩입니다.
    let avatarPadding: CGFloat
    /// 닉네임 텍스트 폰트입니다.
    let nameFont: Font
    /// 액션 버튼 텍스트 폰트입니다.
    let buttonFont: Font
    /// 액션 아이콘 크기입니다.
    let buttonIconSize: CGFloat
    /// 액션 아이콘 패딩입니다.
    let buttonIconPadding: CGFloat
    /// 버튼 상하 패딩입니다.
    let buttonVerticalPadding: CGFloat
    /// 버튼 간 간격입니다.
    let buttonSpacing: CGFloat
    /// 헤더 아래 시작 패딩입니다.
    let topPadding: CGFloat

    /// 아바타 전체 지름(아이콘 + 패딩)입니다.
    var avatarDiameter: CGFloat {
        avatarSize + (avatarPadding * 2)
    }

    /// 화면 사이즈 클래스에 맞는 스타일 세트를 반환합니다.
    static func make(isRegular: Bool) -> ProfileStyle {
        ProfileStyle(
            avatarSize: isRegular ? 56 : 28,
            avatarPadding: isRegular ? 56 : 32,
            nameFont: isRegular ? .largeTitle.bold() : .title2.bold(),
            buttonFont: isRegular ? .title3 : .headline,
            buttonIconSize: isRegular ? 30 : 20,
            buttonIconPadding: isRegular ? 16 : 12,
            buttonVerticalPadding: isRegular ? 20 : 12,
            buttonSpacing: isRegular ? 28 : 18,
            topPadding: isRegular ? Spacing.pv10 * 2 : Spacing.pv10
        )
    }
}
