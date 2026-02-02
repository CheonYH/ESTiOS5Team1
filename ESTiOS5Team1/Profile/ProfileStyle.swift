//
//  ProfileStyle.swift
//  ESTiOS5Team1
//
//  Created by Codex on 1/30/26.
//

import SwiftUI

struct ProfileStyle {
    // 프로필 화면 전용 크기/여백 묶음
    let avatarSize: CGFloat
    let avatarPadding: CGFloat
    let nameFont: Font
    let buttonFont: Font
    let buttonIconSize: CGFloat
    let buttonIconPadding: CGFloat
    let buttonVerticalPadding: CGFloat
    let buttonSpacing: CGFloat
    let topPadding: CGFloat

    var avatarDiameter: CGFloat {
        avatarSize + (avatarPadding * 2)
    }

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
