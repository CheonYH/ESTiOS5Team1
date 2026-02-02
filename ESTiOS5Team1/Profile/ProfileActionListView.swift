//
//  ProfileActionListView.swift
//  ESTiOS5Team1
//
//  Created by Codex on 1/30/26.
//

import SwiftUI

/// 프로필 하단 액션 버튼 목록(닉네임/선호 장르/로그아웃/회원 탈퇴) 뷰입니다.
///
/// 액션 트리거는 콜백으로 위임하고,
/// 공통 카드 UI를 `actionRow`로 재사용합니다.
struct ProfileActionListView: View {
    /// 기기 크기에 맞춘 화면 스타일 토큰입니다.
    let style: ProfileStyle
    /// 닉네임 변경 버튼 탭 콜백입니다.
    let onNicknameTap: () -> Void
    /// 선호 장르 변경 버튼 탭 콜백입니다.
    let onGenrePreferenceTap: () -> Void
    /// 로그아웃 버튼 탭 콜백입니다.
    let onLogoutTap: () -> Void
    /// 회원 탈퇴 버튼 탭 콜백입니다.
    let onDeleteTap: () -> Void
    /// 현재 닉네임 텍스트입니다.
    let nicknameText: String

    /// 닉네임 변경 알럿 표시 상태입니다.
    @Binding var showNickNameAlert: Bool
    /// 닉네임 입력값 바인딩입니다.
    @Binding var newNickname: String
    /// 닉네임 변경 확정 콜백입니다.
    let onConfirmNickname: () -> Void

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
            .alert("닉네임 변경", isPresented: $showNickNameAlert) {
                TextField("새 닉네임", text: $newNickname)
                Button("취소", role: .cancel) {}
                Button("변경") {
                    onConfirmNickname()
                }
            } message: {
                Text("새 닉네임을 입력해 주세요")
            }

            Button(action: onGenrePreferenceTap) {
                actionRow(
                    icon: "slider.horizontal.3",
                    title: "선호 장르 변경",
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
    /// 공통 액션 카드 UI를 생성합니다.
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
