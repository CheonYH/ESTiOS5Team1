//
//  ProfileActionListView.swift
//  ESTiOS5Team1
//
//  Created by Codex on 1/30/26.
//

import SwiftUI

struct ProfileActionListView: View {
    let style: ProfileStyle
    let onNicknameTap: () -> Void
    let onLogoutTap: () -> Void
    let onDeleteTap: () -> Void

    var body: some View {
        VStack(spacing: style.buttonSpacing) {
            // 프로필 주요 액션
            Button(action: onNicknameTap) {
                actionRow(
                    icon: "person.fill",
                    title: "닉네임 변경",
                    iconColor: .purplePrimary,
                    iconBackground: Color(red: 42/255, green: 25/255, blue: 58/255),
                    borderColor: .purplePrimary.opacity(0.7),
                    textColor: .textPrimary,
                    cardColor: Color(red: 19/255, green: 13/255, blue: 23/255),
                    cardBorder: .purplePrimary.opacity(0.8)
                )
            }
            .buttonStyle(.plain)

            Button(action: onLogoutTap) {
                actionRow(
                    icon: "lock.fill",
                    title: "로그아웃",
                    iconColor: .purplePrimary,
                    iconBackground: Color(red: 46/255, green: 32/255, blue: 72/255),
                    borderColor: .purplePrimary.opacity(0.8),
                    textColor: .textPrimary,
                    cardColor: Color(red: 19/255, green: 13/255, blue: 23/255),
                    cardBorder: .purplePrimary.opacity(0.8)
                )
            }
            .buttonStyle(.plain)

            Button(action: onDeleteTap) {
                actionRow(
                    icon: "trash",
                    title: "회원 탈퇴",
                    iconColor: .red.opacity(0.9),
                    iconBackground: Color(red: 55/255, green: 20/255, blue: 19/255),
                    borderColor: .red.opacity(0.8),
                    textColor: .textPrimary,
                    cardColor: Color(red: 21/255, green: 11/255, blue: 11/255),
                    cardBorder: .red.opacity(0.55)
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func actionRow(
        icon: String,
        title: String,
        iconColor: Color,
        iconBackground: Color,
        borderColor: Color,
        textColor: Color,
        cardColor: Color,
        cardBorder: Color
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: style.buttonIconSize, height: style.buttonIconSize)
                .foregroundStyle(iconColor)
                .padding(style.buttonIconPadding)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: 1)
                )

            Text(title)
                .foregroundStyle(textColor)
                .font(style.buttonFont)
                .padding(.leading, 10)

            Spacer()
        }
        .padding(.vertical, style.buttonVerticalPadding)
        .padding(.horizontal, Spacing.pv10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cardColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(cardBorder, lineWidth: 1)
        )
    }
}
