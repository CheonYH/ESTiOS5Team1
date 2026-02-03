//
//  ProfileHeaderView.swift
//  ESTiOS5Team1
//
//  Created by Codex on 1/30/26.
//

import SwiftUI
import PhotosUI

/// 프로필 상단(아바타/닉네임) 영역입니다.
///
/// - Parameters:
///   - style: 화면 스케일 토큰
///   - avatarURLString: 표시할 아바타 URL 문자열
///   - nicknameText: 표시할 닉네임
struct ProfileHeaderView: View {
    let style: ProfileStyle
    let avatarURLString: String
    let nicknameText: String

    @Binding var showPhotoPicker: Bool
    @Binding var selectedItem: PhotosPickerItem?
    let onPhotoPicked: (PhotosPickerItem?) -> Void

    @Binding var showNickNameAlert: Bool
    @Binding var newNickname: String
    let onConfirmNickname: () -> Void

    var body: some View {
        VStack {
            // 아바타 탭 → 사진 선택/업로드
            Button {
                showPhotoPicker = true
            } label: {
                AvatarPickerView(
                    avatarURLString: avatarURLString,
                    avatarDiameter: style.avatarDiameter,
                    avatarSize: style.avatarSize
                )
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { newItem in
                onPhotoPicked(newItem)
            }

            // 닉네임 표시 +
            HStack {
                Text(nicknameText)
                    .foregroundStyle(.textPrimary)
                    .font(style.nameFont)

            }
            .padding(.top, Spacing.pv10)
            .padding(.bottom, Spacing.pv10)
        }
    }
}
