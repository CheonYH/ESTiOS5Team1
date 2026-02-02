//
//  ProfileHeaderView.swift
//  ESTiOS5Team1
//
//  Created by Codex on 1/30/26.
//

import SwiftUI
import PhotosUI

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

            // 닉네임 표시 + 편집 버튼
            HStack {
                Text(nicknameText)
                    .foregroundStyle(.textPrimary)
                    .font(style.nameFont)

                Button {
                    showNickNameAlert = true
                } label: {
                    Image(systemName: "pencil")
                        .resizable()
                        .scaledToFit()
                        .frame(width: style.avatarSize, height: style.avatarSize)
                        .foregroundStyle(.purplePrimary)
                        .padding(Spacing.pv10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 37/255, green: 37/255, blue: 57/255))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.purplePrimary.opacity(0.6), lineWidth: 1)
                        )
                        .padding()
                }
                .alert("닉네임 변경", isPresented: $showNickNameAlert) {
                    TextField("새 닉네임", text: $newNickname)
                    Button("취소", role: .cancel) {}
                    Button("변경") {
                        onConfirmNickname()
                    }
                } message: {
                    Text("새 닉네임을 입력해 주세요")
                }
            }
            .padding(.vertical, Spacing.cr)
        }
    }
}
