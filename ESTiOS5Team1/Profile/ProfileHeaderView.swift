//
//  ProfileHeaderView.swift
//  ESTiOS5Team1
//
//  Created by Codex on 1/30/26.
//

import SwiftUI
import PhotosUI

/// 프로필 상단(아바타/닉네임) 영역을 담당하는 뷰입니다.
///
/// 사진 선택과 닉네임 표시 UI만 담당하고,
/// 실제 업로드/저장 로직은 상위(ViewModel)에서 주입받아 처리합니다.
struct ProfileHeaderView: View {
    /// 기기 크기에 맞춘 화면 스타일 토큰입니다.
    let style: ProfileStyle
    /// 아바타 이미지 URL 문자열입니다.
    let avatarURLString: String
    /// 화면에 표시할 닉네임입니다.
    let nicknameText: String

    /// 사진 피커 표시 상태입니다.
    @Binding var showPhotoPicker: Bool
    /// 사용자가 선택한 사진 항목입니다.
    @Binding var selectedItem: PhotosPickerItem?
    /// 사진 선택 이후 후처리(업로드 등) 콜백입니다.
    let onPhotoPicked: (PhotosPickerItem?) -> Void

    /// 닉네임 변경 알럿 표시 상태입니다. (상위 뷰와 상태 공유)
    @Binding var showNickNameAlert: Bool
    /// 닉네임 입력 바인딩입니다.
    @Binding var newNickname: String
    /// 닉네임 변경 확정 콜백입니다.
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
